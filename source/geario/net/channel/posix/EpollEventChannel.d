module geario.net.channel.posix.EpollEventChannel;

// dfmt off
version (HAVE_EPOLL) : 
// dfmt on

import geario.event.selector.Selector;
import geario.net.channel.Types;
import geario.net.channel.AbstractChannel;
import geario.logging.ConsoleLogger;

// import std.conv;
import std.socket;
import core.sys.posix.unistd;
import core.sys.linux.sys.eventfd;

/**
    https://stackoverflow.com/questions/5355791/linux-cant-get-eventfd-to-work-with-epoll-together
*/
class EpollEventChannel : EventChannel {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        this.handle = cast(socket_t)eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
        _isRegistered = true;
    }

    ~this() {
        // Close();
    }

    override void trigger() {
        version (GEAR_IO_DEBUG) Tracef("trigger the epoll selector.");
        int r = eventfd_write(this.handle, 1);
        //do_sock_write(r);
        if(r != 0) {
            Warningf("Error: %d", r);
        }        
    }

    override void OnWrite() {
        version (GEAR_IO_DEBUG) Tracef("eventLoop running: %s, [fd=%d]", eventLoop.IsRuning, this.handle);
        version (GEAR_IO_DEBUG) Warning("do nothing");
    }

    override void OnRead() {
        this.ClearError();
        uint64_t value;
        int r = eventfd_read(this.handle, &value);
        //do_sock_read(r); 
        version (GEAR_IO_DEBUG) {
            Tracef("result=%d, value=%d, fd=%d", r, value, this.handle);
            if(r != 0) {
                Warningf("Error: %d", r);
            }
        }
    }

    override void OnClose() {
        version (GEAR_IO_DEBUG) Tracef("onClose, [fd=%d]...", this.handle);
        super.OnClose();
        core.sys.posix.unistd.close(this.handle);
        version (GEAR_IO_DEBUG_MORE) Tracef("onClose done, [fd=%d]", this.handle);
    }

}
