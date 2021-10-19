module gear.net.channel.posix.AbstractDatagramSocket;

// dfmt off
version(Posix):
// dfmt on

import gear.event.selector.Selector;
import gear.Functions;
import gear.net.channel.AbstractSocketChannel;
import gear.net.channel.Common;
import gear.logging.ConsoleLogger;

import std.socket;

/**
UDP Socket
*/
abstract class AbstractDatagramSocket : AbstractSocketChannel {
    this(Selector loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4096 * 2) {
        super(loop, ChannelType.UDP);
        setFlag(ChannelFlag.Read, true);
        setFlag(ChannelFlag.ETMode, false);

        this.socket = new UdpSocket(family);
        // _socket.blocking = false;
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[bufferSize];

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
        socket.bind(_bindAddress);
        _binded = true;
    }

    final bool IsBind() {
        return _binded;
    }

    Address BindAddr() {
        return _bindAddress;
    }

    protected UdpDataObject _readBuffer;
    protected bool _binded = false;
    protected Address _bindAddress;

    protected bool tryRead(scope SimpleActionHandler read) {
        this._readBuffer.addr = CreateAddress(this.socket.addressFamily, 0);
        auto data = this._readBuffer.data;
        scope (exit)
            this._readBuffer.data = data;
        // auto len = this.socket.receiveFrom(this._readBuffer.data, this._readBuffer.addr);

        auto len = this.socket.receiveFrom(this._readBuffer.data, this._readBuffer.addr);
        if (len > 0) {
            this._readBuffer.data = this._readBuffer.data[0 .. len];
            read(this._readBuffer);
        }
        return false;
    }

    override void OnWrite() {
        version (GEAR_DEBUG)
            Tracef("try to write [fd=%d]", this.handle);
    }
}