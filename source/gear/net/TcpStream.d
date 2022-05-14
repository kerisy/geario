/*
 * Archttp - A highly performant web framework written in D.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.net.TcpStream;

import gear.net.channel.Types;
import gear.net.TcpStreamOptions;
import gear.net.IoError;

import nbuff;

import gear.event.selector.Selector;
import gear.event;
import gear.Functions;
import gear.logging.ConsoleLogger;

import std.exception;
import std.format;
import std.socket;
import std.string;

import core.atomic;
import core.stdc.errno;
import core.thread;
import core.time;

version (HAVE_EPOLL) {
    import core.sys.linux.netinet.tcp : TCP_KEEPCNT;
}



/**
 *
 */
class TcpStream : AbstractStream {
    SimpleEventHandler closeHandler;
    protected shared bool _isConnected; // It's always true for server.

    protected TcpStreamOptions _tcpOption;
    protected int retryCount = 0;

    // for client
    this(Selector loop, TcpStreamOptions option = null, AddressFamily family = AddressFamily.INET) {
        _isClient = true;
        _isConnected = false;

        if (option is null)
            _tcpOption = TcpStreamOptions.Create();
        else
            _tcpOption = option;
        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);
        super(loop, family, _tcpOption.bufferSize);
        version(GEAR_IO_DEBUG) Tracef("buffer size: %d bytes", _tcpOption.bufferSize);
        

    }

    // for server
    this(Selector loop, Socket socket, TcpStreamOptions option = null) {
        if (option is null)
            _tcpOption = TcpStreamOptions.Create();
        else
            _tcpOption = option;
        this.socket = socket;
        super(loop, socket.addressFamily, _tcpOption.bufferSize);
        _remoteAddress = socket.remoteAddress();
        _localAddress = socket.localAddress();

        _isClient = false;
        _isConnected = true;
        SetKeepalive();
    }

    void options(TcpStreamOptions option) @property {
        assert(option !is null);
        this._tcpOption = option;
    }

    TcpStreamOptions options() @property {
        return this._tcpOption;
    }

    override bool IsBusy() {
        return _isWritting;
    }

    
    override bool IsClient() {
        return _isClient;
    }

    void Connect(string hostname, ushort port) {
        Address[] addresses = getAddress(hostname, port);
        if(addresses is null) {
            throw new SocketException("Can't resolve hostname: " ~ hostname);
        }
        Address selectedAddress;
        foreach(Address addr; addresses) {
            string ip = addr.toAddrString();
            if(ip.startsWith("::")) // skip IPV6
                continue;
            if(ip.length <= 16) {
                selectedAddress = addr;
                break;
            }
        }

        if(selectedAddress is null) {
            Warning("No IPV4 avaliable");
            selectedAddress = addresses[0];
        }
        version(GEAR_IO_DEBUG) {
            Infof("connecting with: hostname=%s, ip=%s, port=%d ", hostname, selectedAddress.toAddrString(), port);
        }
        Connect(selectedAddress); // always select the first one.
    }

    void Connect(Address addr) {
        if (_isConnected)
            return;

        _remoteAddress = addr;
        import std.parallelism;

        auto connectionTask = task(&DoConnect, addr);
        taskPool.put(connectionTask);
        // DoConnect(addr);
    }

    void ReConnect() {
        if (!_isClient) {
            throw new Exception("Only client can call this method.");
        }

        if (_isConnected || retryCount >= _tcpOption.retryTimes)
            return;

        retryCount++;
        _isConnected = false;
        this.socket = new Socket(this._family, SocketType.STREAM, ProtocolType.TCP);

        version (GEAR_DEBUG)
            Tracef("reconnecting %d...", retryCount);
        Connect(_remoteAddress);
    }

    protected override bool DoConnect(Address addr)  {
        try {
            version (GEAR_DEBUG)
                Tracef("Connecting to %s...", addr);
            // Address binded = CreateAddress(this.socket.addressFamily);
            // this.socket.Bind(binded);
            version (HAVE_IOCP) {
                this.socket.blocking = false;
                Start();
                if(super.DoConnect(addr)) {
                    this.socket.blocking = false;
                    SetKeepalive();
                    _localAddress = this.socket.LocalAddress();
                    _isConnected = true;
                } else {
                    ErrorOccurred(ErrorCode.CONNECTIONEFUSED,"Connection refused");
                    _isConnected = false;
                }
            } else {
                this.socket.blocking = true;
                if(super.DoConnect(addr)) {
                    this.socket.blocking = false;
                    SetKeepalive();
                    _localAddress = this.socket.localAddress();
                    Start();
                    _isConnected = true;
                } else {
                    ErrorOccurred(ErrorCode.CONNECTIONEFUSED,"Connection refused");
                    _isConnected = false;
                }
            }
        } catch (Throwable ex) {
            // Must try the best to catch all the exceptions, because it will be executed in another thread.
            debug Warning(ex.msg);
            version(GEAR_DEBUG) Warning(ex);
            ErrorOccurred(ErrorCode.CONNECTIONEFUSED,"Connection refused");
            _isConnected = false;
        } 

        if (_connectionHandler !is null) {
            try {
                _connectionHandler(_isConnected);

            } catch(Throwable ex) {
                debug Warning(ex.msg);
                version(GEAR_DEBUG) Warning(ex);
            }
        }
        return true;
    }

    // www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/
    // http://www.importnew.com/27624.html
    protected void SetKeepalive() {
        version(GEAR_DEBUG) {
            Infof("isKeepalive: %s, keepaliveTime: %d seconds, Interval: %d seconds", 
                _tcpOption.isKeepalive, _tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
        }
        version (HAVE_EPOLL) {
            if (_tcpOption.isKeepalive) {
                this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
                this.setOption(SocketOptionLevel.TCP,
                        cast(SocketOption) TCP_KEEPCNT, _tcpOption.keepaliveProbes);
                // version (GEAR_DEBUG) CheckKeepAlive();
            }
        } else version (HAVE_IOCP) {
            if (_tcpOption.isKeepalive) {
                this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
                // this.setOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT,
                //     _tcpOption.keepaliveProbes);
                // version (GEAR_DEBUG) CheckKeepAlive();
            }
        }
    }

    version (GEAR_DEBUG) protected void CheckKeepAlive() {
        version (HAVE_EPOLL) {
            int time;
            int ret1 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPIDLE, time);
            Tracef("ret=%d, time=%d", ret1, time);

            int interval;
            int ret2 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPINTVL, interval);
            Tracef("ret=%d, interval=%d", ret2, interval);

            int isKeep;
            int ret3 = getOption(SocketOptionLevel.SOCKET, SocketOption.KEEPALIVE, isKeep);
            Tracef("ret=%d, keepalive=%s", ret3, isKeep == 1);

            int probe;
            int ret4 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, probe);
            Tracef("ret=%d, interval=%d", ret4, probe);
        }
    }

    TcpStream Connected(ConnectionHandler handler) {
        _connectionHandler = handler;
        return this;
    }

    TcpStream Received(DataReceivedHandler handler) {
        dataReceivedHandler = handler;
        return this;
    }

    TcpStream Writed(DataSendedHandler handler) {
        dataSendedHandler = handler;
        return this;
    }
    
    TcpStream Closed(SimpleEventHandler handler) {
        closeHandler = handler;
        return this;
    }

    TcpStream Disconnected(SimpleEventHandler handler) {
        disconnectionHandler = handler;
        return this;
    }

    TcpStream Error(ErrorEventHandler handler) {
        errorHandler = handler;
        return this;
    }

    override bool IsConnected() nothrow {
        return _isConnected;
    }

    override void Start() {
        if (_isRegistered)
            return;
        _loop.Register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
        {
        //    this.BeginRead();
        }
    }

    void Write(NbuffChunk bytes) {
        assert(!bytes.empty());

        if (!_isConnected) {
            throw new Exception(format("The connection %s closed!",
                this.RemoteAddress.toString()));
        }

        version (GEAR_IO_DEBUG)
            Infof("data buffered (%s bytes): fd=%d", cast(string)bytes.data, this.handle);
        _isWritting = true;
        InitializeWriteQueue();
        _senddingBuffer.append(bytes);
        OnWrite();
    }

    /**
     * 
     */
    void Write(const(ubyte)[] data) {
        
        NbuffChunk bytes = NbuffChunk(cast(string) data);

        version (GEAR_IO_DEBUG_MORE) {
            Infof("%d bytes(fd=%d): %(%02X %)", data.length, this.handle, data[0 .. $]);
        } else  version (GEAR_IO_DEBUG) {
            if (data.length <= 32)
                Infof("%d bytes(fd=%d): %(%02X %)", data.length, this.handle, data[0 .. $]);
            else
                Infof("%d bytes(fd=%d): %(%02X %)", data.length, this.handle, data[0 .. 32]);
        }

        if(data is null) {
            version(GEAR_DEBUG) {
                Warning("Writting a empty data on connection %s.", this.RemoteAddress.toString());
            }
            return;
        }

        if (!_isConnected) {
            string msg = format("The connection %s is closed!", this.RemoteAddress.toString());
            throw new Exception(msg);
        }

        version (HAVE_IOCP) {
            return Write(bytes);
        } else {

            if (_senddingBuffer.empty() && !_isWritting) {
                _isWritting = true;
                const(ubyte)[] d = data;

                // while (!IsClosing() && !_isWriteCancelling && d.length > 0) {
                while(d !is null) {
                    if(isWriteCancelling()) {
                        _errorMessage = format("The connection %s is cancelled!", this.RemoteAddress.toString());
                        _error = true;
                        Warningf(_errorMessage);
                        throw new Exception(_errorMessage);
                        // break;
                    }

                    if(IsClosing() || IsClosed()) {
                        _errorMessage= format("The connection %s is closing or closed!", this.RemoteAddress.toString());
                        _error = true;
                        Warningf("%s, %s", IsClosing(), IsClosed());
                        throw new Exception(_errorMessage);
                        // break;
                    }

                    version (GEAR_IO_DEBUG)
                        Infof("to write directly %d bytes, fd=%d", d.length, this.handle);
                    size_t nBytes = TryWrite(d);
                    // call Writed handler?
                    // dataSendedHandler(nBytes);

                    if (nBytes == d.length) {
                        version (GEAR_IO_DEBUG)
                            Tracef("write all out at once: %d / %d bytes, fd=%d", nBytes, d.length, this.handle);
                        CheckAllWriteDone();
                        break;
                    } else if (nBytes > 0) {
                        version (GEAR_IO_DEBUG)
                            Tracef("write out partly: %d / %d bytes, fd=%d", nBytes, d.length, this.handle);
                        d = d[nBytes .. $];
                    } else {
                        version (GEAR_IO_DEBUG)
                            Warningf("buffering data: %d bytes, fd=%d", d.length, this.handle);
                        InitializeWriteQueue();
                        _senddingBuffer.append(bytes);
                        break;
                    }
                }
            } else {
                Write(bytes);
            }
        }
    }

    void ShutdownInput() {
        this.socket.shutdown(SocketShutdown.RECEIVE);
    }

    void ShutdownOutput() {
        this.socket.shutdown(SocketShutdown.SEND);
    }

    override protected void OnDisconnected() {
        version(GEAR_DEBUG) {
            Infof("peer disconnected: fd=%d", this.handle);
        }
        if (disconnectionHandler !is null)
            disconnectionHandler();

        this.Close();
    }

protected:
    bool _isClient;
    ConnectionHandler _connectionHandler;

    override void OnRead() {
        version (GEAR_IO_DEBUG)
            Trace("start to read");

        version (Posix) {
            // todo: new buffer 
            while (!_isClosed && !TryRead()) {
                version (GEAR_IO_DEBUG)
                    Trace("continue reading...");
            }
            // onDataReceived
        } else {
            if (!_isClosed)
            {
                DoRead();
            }

        }

        //if (this.isError) {
        //    string msg = format("Socket Error on read: fd=%d, code=%d, message: %s",
        //            this.handle, errno, this.errorMessage);
        //    debug errorf(msg);
        //    if (!IsClosed())
        //        ErrorOccurred(msg);
        //}
    }

    override void OnClose() {
        bool lastConnectStatus = _isConnected;
        super.OnClose();
        if(lastConnectStatus) {
            version (GEAR_IO_DEBUG) {
                if (!_senddingBuffer.empty()) {
                    Warningf("Some data has not been sent yet: fd=%d", this.handle);
                }
            }
            version(GEAR_DEBUG) {
                Infof("Closing a connection with: %s, fd=%d", this.RemoteAddress, this.handle);
            }

            ResetWriteStatus();
            _isConnected = false;
            version (GEAR_IO_DEBUG) {
                Infof("Raising a event on a TCP stream [%s] is down: fd=%d", 
                    this.RemoteAddress.toString(), this.handle);
            }

            if (closeHandler !is null)
                closeHandler();
        }
    }

}
