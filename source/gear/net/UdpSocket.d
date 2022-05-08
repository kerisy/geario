/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.net.UdpSocket;

import gear.event;
import gear.logging;

import std.socket;
import std.exception;

/**
*/
class UdpSocket : AbstractDatagramSocket {

    private UdpDataHandler _receivedHandler;

    this(EventLoop loop, AddressFamily amily = AddressFamily.INET) {
        super(loop, amily);
    }
    
    UdpSocket enableBroadcast(bool flag) {
        this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, flag);
        return this;
    }

    UdpSocket onReceived(UdpDataHandler handler) {
        _receivedHandler = handler;
        return this;
    }

    ptrdiff_t sendTo(const(void)[] buf, Address to) {
        return this.socket.sendTo(buf, to);
    }

    ptrdiff_t sendTo(const(void)[] buf) {
        return this.socket.sendTo(buf);
    }

    ptrdiff_t sendTo(const(void)[] buf, SocketFlags flags, Address to) {
        return this.socket.sendTo(buf, flags, to);
    }

    UdpSocket Bind(string ip, ushort port) {
        super.Bind(parseAddress(ip, port));
        return this;
    }

    UdpSocket Bind(Address address) {
        super.Bind(address);
        return this;
    }

    UdpSocket Connect(Address addr) {
        this.socket.connect(addr);
        return this;
    }

    override void Start() {
        if (!_binded) {
            socket.bind(_bindAddress);
            _binded = true;
        }

        _inLoop.Register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
            DoRead();
    }

    protected override void OnRead() nothrow {
        catchAndLogException(() {
            bool canRead = true;
            while (canRead && _isRegistered) {
                version (GEAR_IO_DEBUG)
                    Trace("reading data...");
                canRead = tryRead((Object obj) nothrow{
                    collectException(() {
                        UdpDataObject data = cast(UdpDataObject) obj;
                        if (data !is null) {
                            _receivedHandler(data.data, data.addr);
                        }
                    }());
                });

                if (this.IsError) {
                    canRead = false;
                    this.Close();
                    LogError("UDP socket Error: ", this.ErrorMessage);
                }
            }
        }());
    }

}
