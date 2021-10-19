module gear.net.channel.posix;

// dfmt off
version(Posix):
// dfmt on

public import gear.net.channel.posix.AbstractDatagramSocket;
public import gear.net.channel.posix.AbstractListener;
public import gear.net.channel.posix.AbstractStream;

version (HAVE_EPOLL) {
    public import gear.net.channel.posix.EpollEventChannel;
}

version(HAVE_KQUEUE) {
    public import gear.net.channel.posix.KqueueEventChannel;
}