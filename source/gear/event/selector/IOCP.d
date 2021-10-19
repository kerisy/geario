/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.event.selector.IOCP;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import gear.event.selector.Selector;
import gear.net.channel.Common;
import gear.net.channel;
import gear.event.timer;
import gear.logging.ConsoleLogger;
import gear.system.Error;
import gear.net.channel.iocp.AbstractStream;
import core.sys.windows.windows;
import std.conv;
import std.socket;
import gear.util.worker;
import std.container : DList;


/**
 * 
 */
class AbstractSelector : Selector {

    this(size_t number, size_t divider, Worker worker = null, size_t maxChannels = 1500) {
        super(number, divider, worker, maxChannels);
        _iocpHandle = CreateIoCompletionPort(INVALID_HANDLE_VALUE, null, 0, 0);
        if (_iocpHandle is null)
            errorf("CreateIoCompletionPort failed: %d\n", GetLastError());
        _timer.init();
        _stopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    }

    ~this() {
        // import std.socket;
        // std.socket.close(_iocpHandle);
    }

    override bool Register(AbstractChannel channel) {
        super.Register(channel);

        ChannelType ct = channel.type;
        auto fd = channel.handle;
        version (GEAR_IO_DEBUG)
            Tracef("register, channel(fd=%d, type=%s)", fd, ct);

        if (ct == ChannelType.Timer) {
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            assert(timerChannel !is null);
            if (!timerChannel.setTimerOut())
                return false;
            _timer.timeWheel().addNewTimer(timerChannel.timer, timerChannel.wheelSize());
        } else if (ct == ChannelType.TCP
                || ct == ChannelType.Accept || ct == ChannelType.UDP) {
            version (GEAR_IO_DEBUG)
                Trace("Run CreateIoCompletionPort on socket: ", fd);

            // _event.SetNext(channel);
            CreateIoCompletionPort(cast(HANDLE) fd, _iocpHandle,
                    cast(size_t)(cast(void*) channel), 0);

            //cast(AbstractStream)channel)
        } else {
            Warningf("Can't register a channel: %s", ct);
        }

        auto stream = cast(AbstractStream)channel;
        if (stream !is null && !stream.IsClient()) {
            stream.BeginRead();
        }

        return true;
    }

    override bool Deregister(AbstractChannel channel) {
        // FIXME: Needing refactor or cleanup -@Administrator at 8/28/2018, 3:28:18 PM
        // https://stackoverflow.com/questions/6573218/removing-a-handle-from-a-i-o-completion-port-and-other-questions-about-iocp
        version(GEAR_IO_DEBUG) 
        Tracef("deregister (fd=%d)", channel.handle);



        // IocpContext _data;
        // _data.channel = channel;
        // _data.operation = IocpOperation.close;
        // PostQueuedCompletionStatus(_iocpHandle, 0, 0, &_data.overlapped);
        //(cast(AbstractStream)channel).stopAction();
        //WaitForSingleObject
        return super.Deregister(channel);
    }

    // void weakUp() {
    //     IocpContext _data;
    //     // _data.channel = _event;
    //     _data.operation = IocpOperation.event;

    //     // PostQueuedCompletionStatus(_iocpHandle, 0, 0, &_data.overlapped);
    //     PostQueuedCompletionStatus(_iocpHandle, 0, 0, null);
    // }

    override void OnLoop(long timeout = -1) {
        _timer.init();
        super.OnLoop(timeout);
    }

    protected override int DoSelect(long t) {
        auto timeout = _timer.doWheel();
        OVERLAPPED* overlapped;
        ULONG_PTR key = 0;
        DWORD bytes = 0;
        IocpContext* ev;

        while( WAIT_OBJECT_0 != WaitForSingleObject(_stopEvent , 0) && !IsStopping()) {
            // https://docs.microsoft.com/zh-cn/windows/win32/api/ioapiset/nf-ioapiset-getqueuedcompletionstatus
            const int ret = GetQueuedCompletionStatus(_iocpHandle, &bytes, &key,
                    &overlapped, INFINITE);
            
            ev = cast(IocpContext*) overlapped;
            // ev = cast(IocpContext *)( cast(PCHAR)(overlapped) - cast(ULONG_PTR)(&(cast(IocpContext*)0).overlapped));
            if (ret == 0) {
                DWORD dwErr = GetLastError();
                if (WAIT_TIMEOUT == dwErr) {
                    continue;
                } else {
                    assert(ev !is null, "The IocpContext is null");
                    AbstractChannel channel = ev.channel;
                    if (channel !is null && !channel.IsClosed()) {
                        channel.Close();
                    }
                    continue;
                }
            } else if (ev is null || ev.channel is null) {
               version(GEAR_IO_DEBUG) Warningf("The ev is null or ev.watche is null. isStopping: %s", IsStopping());
            } else {
                if (0 == bytes && (ev.operation == IocpOperation.read || ev.operation == IocpOperation.write)) {
                    AbstractChannel channel = ev.channel;
                    if (channel !is null && !channel.IsClosed()) {
                        channel.Close();
                    }
                    continue;
                } else {
                    HandleChannelEvent(ev.operation, ev.channel, bytes);
                }
            }
        }

        return 0;
    }

    private void HandleChannelEvent(IocpOperation op, AbstractChannel channel, DWORD bytes) {

        version (GEAR_IO_DEBUG)
            Infof("ev.operation: %s, fd=%d", op, channel.handle);

        switch (op) {
            case IocpOperation.accept:
                channel.OnRead();
                break;
            case IocpOperation.connect:
                OnSocketRead(channel, 0);
                (cast(AbstractStream)channel).BeginRead();
                break;
            case IocpOperation.read:
                OnSocketRead(channel, bytes);
                break;
            case IocpOperation.write:
                OnSocketWrite(channel, bytes);
                break;
            case IocpOperation.event:
                channel.OnRead();
                break;
            case IocpOperation.close:
                break;
            default:
                Warning("unsupported operation type: ", op);
            break;
        }
    }

    override void Stop() {
        super.Stop();
        // weakUp();
        PostQueuedCompletionStatus(_iocpHandle, 0, 0, null);
    }

    void HandleTimer() {

    }

    // override void Dispose() {

    // }

    private void OnSocketRead(AbstractChannel channel, size_t len) {
        debug if (channel is null) {
            Warning("channel is null");
            return;
        }

        if (channel is null)
        {
            Warning("channel is null");
            return;
        }

        // (cast(AbstractStream)channel).setBusyWrite(false);

        if (len == 0 || channel.isClosed) {
            version (GEAR_IO_DEBUG)
               Infof("channel [fd=%d] closed. isClosed: %s, len: %d", channel.handle, channel.isClosed, len);
            //channel.Close();
            return;
        }

        AbstractSocketChannel socketChannel = cast(AbstractSocketChannel) channel;
        // assert(socketChannel !is null, "The type of channel is: " ~ typeid(channel).name);
        if (socketChannel is null) {
            Warning("The channel socket is null: ");
        } else {
            socketChannel.setRead(len);
            channel.OnRead();
        }
    }

    private void OnSocketWrite(AbstractChannel channel, size_t len) {
        debug if (channel is null) {
            Warning("channel is null");
            return;
        }
        AbstractStream client = cast(AbstractStream) channel;
        // assert(client !is null, "The type of channel is: " ~ typeid(channel).name);
        if (client is null) {
            Warning("The channel socket is null: ");
            return;
        }
        client.OnWriteDone(len); // Notify the client about how many bytes actually sent.
    }


private:
    HANDLE _iocpHandle;
    CustomTimer _timer;
    HANDLE _stopEvent;
}
