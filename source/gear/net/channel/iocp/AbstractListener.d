module gear.net.channel.iocp.AbstractListener;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import gear.event.selector.Selector;
import gear.net.channel.AbstractSocketChannel;
import gear.net.channel.Common;
import gear.net.channel.iocp.Common;
import gear.logging.ConsoleLogger;
import gear.Functions;

import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;

import std.socket;



/**
TCP Server
*/
abstract class AbstractListener : AbstractSocketChannel {
    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4 * 1024) {
        super(loop, ChannelType.Accept);
        setFlag(ChannelFlag.Read, true);
        _buffer = new ubyte[bufferSize];
        this.socket = new TcpSocket(family);

        loadWinsockExtension(this.handle);
    }

    mixin CheckIocpError;

    protected void DoAccept() {
        _iocp.channel = this;
        _iocp.operation = IocpOperation.accept;
        _clientSocket = new Socket(this.localAddress.addressFamily,
                SocketType.STREAM, ProtocolType.TCP);
        DWORD dwBytesReceived = 0;

        version (GEAR_DEBUG) {
            Tracef("client socket: acceptor=%s  inner socket=%s", this.handle,
                    _clientSocket.handle());
            // Info("AcceptEx@", AcceptEx);
        }
        uint sockaddrSize = cast(uint) sockaddr_storage.sizeof;
        // https://docs.microsoft.com/en-us/windows/desktop/api/mswsock/nf-mswsock-acceptex
        BOOL ret = AcceptEx(this.handle, cast(SOCKET) _clientSocket.handle, _buffer.ptr,
                0, sockaddrSize + 16, sockaddrSize + 16, &dwBytesReceived, &_iocp.overlapped);
        version (GEAR_DEBUG)
            Trace("AcceptEx return: ", ret);
        checkErro(ret, FALSE);
    }

    protected bool OnAccept(scope AcceptHandler handler) {
        version (GEAR_DEBUG)
            Trace("a new connection coming...");
        this.ClearError();
        SOCKET slisten = cast(SOCKET) this.handle;
        SOCKET slink = cast(SOCKET) this._clientSocket.handle;
        // void[] value = (&slisten)[0..1];
        // setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, value.ptr,
        //                    cast(uint) value.length);
        version (GEAR_DEBUG)
            Tracef("slisten=%s, slink=%s", slisten, slink);
        setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, cast(void*)&slisten, slisten.sizeof);
        if (handler !is null)
            handler(this._clientSocket);

        version (GEAR_DEBUG)
            Trace("accepting next connection...");
        if (this.isRegistered)
            this.DoAccept();
        return true;
    }

    override void OnClose() {
        
        // version (GEAR_DEBUG)
        //     Tracef("_isWritting=%s", _isWritting);
        // _isWritting = false;
        // assert(false, "");
        // TODO: created by Administrator @ 2018-3-27 15:51:52
    }

    private IocpContext _iocp;
    private WSABUF _dataWriteBuffer;
    private ubyte[] _buffer;
    private Socket _clientSocket;
}
