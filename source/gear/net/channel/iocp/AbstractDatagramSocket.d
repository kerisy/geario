module gear.net.channel.iocp.AbstractDatagramSocket;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

// import gear.buffer.Buffer;
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
UDP Socket
*/
abstract class AbstractDatagramSocket : AbstractSocketChannel {
    /// Constructs a blocking IPv4 UDP Socket.
    this(Selector loop, AddressFamily family = AddressFamily.INET) {
        super(loop, ChannelType.UDP);
        setFlag(ChannelFlag.Read, true);
        // setFlag(ChannelFlag.ETMode, false);

        this.socket = new UdpSocket(family);
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[4096 * 2];

        if (family == AddressFamily.INET)
            _bindAddress = new InternetAddress(InternetAddress.PORT_ANY);
        else if (family == AddressFamily.INET6)
            _bindAddress = new Internet6Address(Internet6Address.PORT_ANY);
        else
            _bindAddress = new UnknownAddress();
    }

    final void Bind(Address addr) {
        if (_binded)
            return;
        _bindAddress = addr;
        socket.Bind(_bindAddress);
        _binded = true;
    }

    final bool IsBind() {
        return _binded;
    }

    Address BindAddr() {
        return _bindAddress;
    }

    override void Start() {
        if (!_binded) {
            socket.Bind(_bindAddress);
            _binded = true;
        }
    }

    // abstract void DoRead();

    private UdpDataObject _readBuffer;
    protected bool _binded = false;
    protected Address _bindAddress;

    mixin CheckIocpError;

    void DoRead() {
        version (GEAR_IO_DEBUG)
            Trace("Receiving......");

        _dataReadBuffer.len = cast(uint) _readBuffer.data.length;
        _dataReadBuffer.buf = cast(char*) _readBuffer.data.ptr;
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.read;
        remoteAddrLen = cast(int) BindAddr().nameLen();

        DWORD dwReceived = 0;
        DWORD dwFlags = 0;

        int nRet = WSARecvFrom(cast(SOCKET) this.handle, &_dataReadBuffer,
                cast(uint) 1, &dwReceived, &dwFlags, cast(SOCKADDR*)&remoteAddr, &remoteAddrLen,
                &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
        checkErro(nRet, SOCKET_ERROR);
    }

    Address buildAddress() {
        Address tmpaddr;
        if (remoteAddrLen == 32) {
            sockaddr_in* addr = cast(sockaddr_in*)(&remoteAddr);
            tmpaddr = new InternetAddress(*addr);
        } else {
            sockaddr_in6* addr = cast(sockaddr_in6*)(&remoteAddr);
            tmpaddr = new Internet6Address(*addr);
        }
        return tmpaddr;
    }

    bool tryRead(scope SimpleActionHandler read) {
        this.ClearError();
        if (this.readLen == 0) {
            read(null);
        } else {
            ubyte[] data = this._readBuffer.data;
            this._readBuffer.data = data[0 .. this.readLen];
            this._readBuffer.addr = this.buildAddress();
            scope (exit)
                this._readBuffer.data = data;
            read(this._readBuffer);
            this._readBuffer.data = data;
            if (this.isRegistered)
                this.DoRead();
        }
        return false;
    }

    IocpContext _iocpread;
    WSABUF _dataReadBuffer;

    sockaddr remoteAddr;
    int remoteAddrLen;

}
