/*
 * Geario - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module geario.event.selector.Epoll;

// dfmt off
version(HAVE_EPOLL):

// dfmt on

import std.exception;
import std.socket;
import std.string;

import core.sys.posix.sys.types;
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;
import core.stdc.string;
import core.stdc.errno;
import core.time;
import core.thread;

import core.sys.posix.sys.resource;
import core.sys.posix.sys.time;
import core.sys.linux.epoll;

import geario.event.selector.Selector;
import geario.Exceptions;
import geario.net.channel;
import geario.logging;
import geario.event.timer;
import geario.system.Error;
import geario.util.worker;

/* Max. theoretical number of file descriptors on system. */
__gshared size_t fdLimit = 0;

shared static this() {
    rlimit fileLimit;
    getrlimit(RLIMIT_NOFILE, &fileLimit);
    fdLimit = fileLimit.rlim_max;
}


/**
 * 
 */
class AbstractSelector : Selector {
    enum int NUM_KEVENTS = 1024;
    private int _epollFD;
    private bool isDisposed = false;
    private epoll_event[NUM_KEVENTS] events;
    private EventChannel _eventChannel;

    this(size_t id, size_t divider, Worker worker = null, size_t maxChannels = 1500) {
        super(id, divider, worker, maxChannels);

        // http://man7.org/linux/man-pages/man2/epoll_create.2.html
        /*
         * Set the close-on-exec (FD_CLOEXEC) flag on the new file descriptor.
         * See the description of the O_CLOEXEC flag in open(2) for reasons why
         * this may be useful.
         */
        _epollFD = epoll_create1(EPOLL_CLOEXEC);
        if (_epollFD < 0)
            throw new IOException("epoll_create failed");

        _eventChannel = new EpollEventChannel(this);
        Register(_eventChannel);
    }

    ~this() @nogc {
        // Dispose();
    }

    override void Dispose() {
        if (isDisposed)
            return;

        version (GEAR_IO_DEBUG)
            log.trace("disposing selector[fd=%d]...", _epollFD);
        isDisposed = true;
        _eventChannel.Close();
        int r = core.sys.posix.unistd.close(_epollFD);
        if(r != 0) {
            version (GEAR_IO_DEBUG) log.warning("Error: %d", r);
        }

        super.Dispose();
    }

    override void OnStop() {
        version (GEAR_IO_DEBUG)
            log.info("Selector stopping. fd=%d, id: %d", _epollFD, GetId());

        if(!_eventChannel.IsClosed()) {
            _eventChannel.trigger();
            // _eventChannel.OnWrite();
        }
    }

    override bool Register(AbstractChannel channel) {
        super.Register(channel);
        
        version (GEAR_IO_DEBUG)
            log.trace("register, channel(fd=%d, type=%s)", channel.handle, channel.Type);

        // epoll_event e;

        // e.data.fd = infd;
        // e.data.ptr = cast(void*) channel;
        // e.events = EPOLLIN | EPOLLET | EPOLLERR | EPOLLHUP | EPOLLRDHUP | EPOLLOUT;
        // int s = epoll_ctl(_epollFD, EPOLL_CTL_ADD, infd, &e);
        // if (s == -1) {
        //     debug log.warning("failed to register channel: fd=%d", infd);
        //     return false;
        // } else {
        //     return true;
        // }
        if (EpollCtl(channel, EPOLL_CTL_ADD)) {
            return true;
        } else {
            debug log.warning("failed to register channel: fd=%d", channel.handle);
            return false;
        }
    }

    override bool Deregister(AbstractChannel channel) {
        scope(exit) {
            super.Deregister(channel);
            version (GEAR_IO_DEBUG)
                log.trace("deregister, channel(fd=%d, type=%s)", channel.handle, channel.Type);
        }

        if (EpollCtl(channel, EPOLL_CTL_DEL)) {
            return true;
        } else {
            log.warning("deregister channel failed: fd=%d", fd);
            return false;
        }
    }

    /**
        timeout: in millisecond
    */
    protected override int DoSelect(long timeout) {
        int len = 0;

        if (timeout <= 0) { /* Indefinite or no wait */
            do {
                // http://man7.org/linux/man-pages/man2/epoll_wait.2.html
                // https://stackoverflow.com/questions/6870158/epoll-wait-fails-due-to-eintr-how-to-remedy-this/6870391#6870391
                len = epoll_wait(_epollFD, events.ptr, events.length, cast(int) timeout);
            } while ((len == -1) && (errno == EINTR));
        } else { /* Bounded wait; bounded restarts */
            len = iEpoll(_epollFD, events.ptr, events.length, cast(int) timeout);
        }

        foreach (i; 0 .. len) {
            AbstractChannel channel = cast(AbstractChannel)(events[i].data.ptr);
            if (channel is null) {
                debug log.warning("channel is null");
            } else {
                ChannelEventHandle(channel, events[i].events);
            }
        }

        return len;
    }

    private void ChannelEventHandle(AbstractChannel channel, uint event) {
        version (GEAR_IO_DEBUG) {
            log.warning("thread: %s", Thread.getThis().name());

            // Thread.sleep(300.msecs);
            log.info("handling event: selector=%d, channel=%d, events=%d, isReadable: %s, isWritable: %s, isClosed: %s", 
                this._epollFD, channel.handle, event, IsReadable(event), IsWritable(event), IsClosed(event));
        }

        try {
            if (IsClosed(event)) { // && errno != EINTR
                /* An Error has occured on this fd, or the socket is not
                    ready for reading (why were we notified then?) */
                version (GEAR_IO_DEBUG) {
                    log.warning("event=%d, isReadable: %s, isWritable: %s", 
                        event, IsReadable(event), IsWritable(event));

                    if (IsError(event)) {
                        log.warning("channel Error: fd=%s, event=%d, errno=%d, message=%s",
                                channel.handle, event, errno, GetErrorMessage(errno));
                    } else {
                        log.info("channel closed: fd=%d, errno=%d, message=%s",
                                    channel.handle, errno, GetErrorMessage(errno));
                    }
                }
                
                // The remote connection broken abnormally, so the channel should be notified.
                if(IsReadable(event)) {
                    channel.OnRead();
                }

                // if(IsWritable(event)) {
                //     channel.OnWrite();
                // }

                channel.Close();
            } else if (event == EPOLLIN) {
                version (GEAR_IO_DEBUG)
                    log.trace("channel read event: fd=%d", channel.handle);
                channel.OnRead();
            } else if (event == EPOLLOUT) {
                version (GEAR_IO_DEBUG)
                    log.trace("channel write event: fd=%d", channel.handle);
                channel.OnWrite();
            } else if (event == (EPOLLIN | EPOLLOUT)) {
                version (GEAR_IO_DEBUG)
                    log.trace("channel read and write: fd=%d", channel.handle);
                channel.OnWrite();
                channel.OnRead();
            } else {
                debug log.warning("Only read/write/close events can be handled, current event: %d", event);
            }
        } catch (Exception e) {
            debug {
                log.error("Error while handing channel: fd=%s, exception=%s, message=%s",
                        channel.handle, typeid(e), e.msg);
            }
            version(GEAR_DEBUG) log.warning(e);
        }
    }

    private int iEpoll(int epfd, epoll_event* events, int numfds, int timeout) {
        long start, now;
        int remaining = timeout;
        timeval t;
        long diff;

        gettimeofday(&t, null);
        start = t.tv_sec * 1000 + t.tv_usec / 1000;

        for (;;) {
            int res = epoll_wait(epfd, events, numfds, remaining);
            if (res < 0 && errno == EINTR) {
                if (remaining >= 0) {
                    gettimeofday(&t, null);
                    now = t.tv_sec * 1000 + t.tv_usec / 1000;
                    diff = now - start;
                    remaining -= diff;
                    if (diff < 0 || remaining <= 0) {
                        return 0;
                    }
                    start = now;
                }
            } else {
                return res;
            }
        }
    }

    // https://blog.csdn.net/ljx0305/article/details/4065058
    private static bool IsError(uint events) nothrow {
        return (events & EPOLLERR) != 0;
    }

    private static bool IsClosed(uint e) nothrow {
        return (e & EPOLLERR) != 0 || (e & EPOLLHUP) != 0 || (e & EPOLLRDHUP) != 0
                || (!(e & EPOLLIN) && !(e & EPOLLOUT)) != 0;
    }

    private static bool IsReadable(uint events) nothrow {
        return (events & EPOLLIN) != 0;
    }

    private static bool IsWritable(uint events) nothrow {
        return (events & EPOLLOUT) != 0;
    }

    private static BuildEpollEvent(AbstractChannel channel, ref epoll_event ev) {
        ev.data.ptr = cast(void*) channel;
        // ev.data.fd = channel.handle;
        ev.events = EPOLLRDHUP | EPOLLERR | EPOLLHUP;
        if (channel.HasFlag(ChannelFlag.Read))
            ev.events |= EPOLLIN;
        if (channel.HasFlag(ChannelFlag.Write))
            ev.events |= EPOLLOUT;
        // if (channel.HasFlag(ChannelFlag.OneShot))
        //     ev.events |= EPOLLONESHOT;
        if (channel.HasFlag(ChannelFlag.ETMode))
            ev.events |= EPOLLET;
        return ev;
    }

    private bool EpollCtl(AbstractChannel channel, int opcode) {
        assert(channel !is null);
        const fd = channel.handle;
        assert(fd >= 0, "The channel.handle is not initialized!");

        epoll_event ev;
        BuildEpollEvent(channel, ev);
        int res = 0;

        do {
            res = epoll_ctl(_epollFD, opcode, fd, &ev);
        }
        while ((res == -1) && (errno == EINTR));

        /*
         * A channel may be registered with several Selectors. When each Selector
         * is polled a EPOLL_CTL_DEL op will be inserted into its pending update
         * list to Remove the file descriptor from epoll. The "last" Selector will
         * close the file descriptor which automatically unregisters it from each
         * epoll descriptor. To avoid costly synchronization between Selectors we
         * allow pending updates to be processed, ignoring errors. The errors are
         * harmless as the last update for the file descriptor is guaranteed to
         * be EPOLL_CTL_DEL.
         */
        if (res < 0 && errno != EBADF && errno != ENOENT && errno != EPERM) {
            log.warning("epoll_ctl failed");
            return false;
        } else
            return true;
    }
}
