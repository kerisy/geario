module geario.net.channel.posix;

// dfmt off
version(Posix):
// dfmt on

public import geario.net.channel.posix.AbstractDatagramSocket;
public import geario.net.channel.posix.AbstractListener;
public import geario.net.channel.posix.AbstractStream;

version (HAVE_EPOLL) {
    public import geario.net.channel.posix.EpollEventChannel;
}

version(HAVE_KQUEUE) {
    public import geario.net.channel.posix.KqueueEventChannel;
}