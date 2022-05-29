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

module geario.net.TcpListener;

public import geario.net.TcpStream;
public import geario.net.TcpStreamOptions;
public import geario.net.IoError;

import geario.net.channel;

import geario.system.Memory : totalCPUs;

import geario.event.EventLoop;
import geario.event.EventLoopThreadPool;
import geario.util.ThreadPool;
import geario.Exceptions;
import geario.Functions;
import geario.logging;
import geario.util.CompilerHelper;

import std.socket;
import std.exception;
import core.thread;
import core.time;

alias AcceptEventHandler = void delegate(TcpListener sender, TcpStream stream);
alias PeerCreateHandler = TcpStream delegate(TcpListener sender, Socket socket, size_t bufferSize);
alias EventErrorHandler = void delegate(IoError Error);

/**
 * 
 */
class TcpListener : AbstractListener
{
    protected bool _isSslEnabled = false;
    protected bool _isBlocking = false;
    protected bool _isBinded = false;

    protected EventLoopThreadPool _loopThreadPool;
    protected size_t _ioThreads;
    protected TcpStreamOptions _tcpStreamoption;
    protected EventHandler _shutdownHandler;

    /// event handlers
    AcceptEventHandler acceptHandler;
    SimpleEventHandler closeHandler;
    PeerCreateHandler peerCreateHandler;
    EventErrorHandler errorHandler;

    private int _backlog = 1024;

    this(EventLoop loop = null, AddressFamily family = AddressFamily.INET, size_t bufferSize = 1024)
    {
        _ioThreads = 1;
        _tcpStreamoption = TcpStreamOptions.Create();
        _tcpStreamoption.bufferSize = bufferSize;

        if (loop is null)
            loop = new EventLoop;
        
        version (HAVE_IOCP)
            super(loop, family, bufferSize);
        else
            super(loop, family);
    }

    TcpListener Threads(size_t ioThreads = totalCPUs)
    {
        _ioThreads = ioThreads > 1 ? ioThreads : 1;
        return this;
    }

    TcpListener Accepted(AcceptEventHandler handler) {
        acceptHandler = handler;
        return this;
    }

    TcpListener Error(EventErrorHandler handler)
    {
        errorHandler = handler;
        return this;
    }

    TcpListener OnPeerCreating(PeerCreateHandler handler) {
        peerCreateHandler = handler;
        return this;
    }

    TcpListener OnShutdown(EventHandler handler) {
        _shutdownHandler = handler;
        return this;
    }

    TcpListener Bind(string ip, ushort port)
    {
        return Bind(parseAddress(ip, port));
    }

    TcpListener Bind(ushort port)
    {
        return Bind(CreateAddress(this.socket.addressFamily, port));
    }

    TcpListener Bind(Address addr)
    {
        try
        {
            this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
            this.socket.bind(addr);
            this.socket.blocking = _isBlocking;
            _localAddress = _socket.localAddress();
            _isBinded = true;
        }
        catch (SocketOSException e)
        {
            if (errorHandler !is null)
            {
                this.errorHandler(new IoError(ErrorCode.ADDRINUSE , e.msg));
            }
        }

        return this;
    }

    Address BindingAddress()
    {
        return _localAddress;
    }

    void Blocking(bool flag)
    {
        _isBlocking = flag;
        // if(_isBinded)
        this.socket.blocking = flag;
    }

    bool Blocking()
    {
        return _isBlocking;
    }

    /**
     * https://stackoverflow.com/questions/14388706/socket-options-so-reuseaddr-and-so-reuseport-how-do-they-differ-do-they-mean-t
     * https://www.cnblogs.com/xybaby/p/7341579.html
     * https://rextester.com/BUAFK86204
     */
    TcpListener ReusePort(bool flag)
    {
        if(_isBinded) {
            throw new IOException("Must be set before binding.");
        }

        version (Posix) {
            import core.sys.posix.sys.socket;

            this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, flag);
            this.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_REUSEPORT, flag);
        } else version (Windows) {
            // https://docs.microsoft.com/en-us/windows/win32/winsock/using-so-reuseaddr-and-so-exclusiveaddruse
            // https://docs.microsoft.com/zh-cn/windows/win32/winsock/so-exclusiveaddruse
            // TODO: Tasks pending completion -@Administrator at 2020-05-25T15:04:42+08:00
            // More tests needed            
            import core.sys.windows.winsock2;
            this.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_EXCLUSIVEADDRUSE, !flag);
        }

        return this;
    }

    TcpListener Listen(int backlog)
    {
        _backlog = backlog;
        return this;
    }

    override void Start()
    {
        if (_ioThreads > 1)
            _loopThreadPool = new EventLoopThreadPool(_ioThreads);

        this.socket.listen(_backlog);
        _loop.Register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
            this.DoAccept();
    }

    override void Close() {
        if (closeHandler !is null)
            closeHandler();
        else if (_shutdownHandler !is null)
            _shutdownHandler(this, null);
        this.OnClose();
    }

    protected override void OnRead() {
        bool canRead = true;
        version (GEAR_DEBUG)
            Trace("start to listen");
        // while(canRead && this.isRegistered) // why??
        {
            version (GEAR_DEBUG)
                Trace("listening...");

            try
            {
                canRead = OnAccept((Socket socket) {

                    version (GEAR_DEBUG) {
                        log.info("new connection from %s, fd=%d",
                        socket.remoteAddress.toString(), socket.handle());
                    }

                    if (acceptHandler !is null) {
                        TcpStream stream;
                        if (peerCreateHandler is null) {
                            if (_ioThreads > 1)
                                stream = new TcpStream(_loopThreadPool.GetNextLoop(), socket, _tcpStreamoption);
                            else
                                stream = new TcpStream(_loop, socket, _tcpStreamoption);
                        }
                        else
                            stream = peerCreateHandler(this, socket, _tcpStreamoption.bufferSize);

                        acceptHandler(this, stream);
                        stream.Start();
                    }
                });

                if (this.IsError) {
                    canRead = false;
                    log.error("listener Error: ", this.ErrorMessage);
                    this.Close();
                }
            }
            catch (SocketOSException e)
            {
                if (errorHandler !is null)
                {
                    errorHandler(new IoError(ErrorCode.OTHER , e.msg));
                }
            }
        }
    }
}

// dfmt off
version(linux):
// dfmt on
static if (CompilerHelper.IsLessThan(2078)) {
    version (X86) {
        enum SO_REUSEPORT = 15;
    } else version (X86_64) {
        enum SO_REUSEPORT = 15;
    } else version (MIPS32) {
        enum SO_REUSEPORT = 0x0200;
    } else version (MIPS64) {
        enum SO_REUSEPORT = 0x0200;
    } else version (PPC) {
        enum SO_REUSEPORT = 15;
    } else version (PPC64) {
        enum SO_REUSEPORT = 15;
    } else version (ARM) {
        enum SO_REUSEPORT = 15;
    }
}

version (AArch64) {
    enum SO_REUSEPORT = 15;
}

version(CRuntime_Musl) {
    enum SO_REUSEPORT = 15;
}
