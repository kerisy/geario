module gear.net.channel.posix.AbstractStream;

// dfmt off
version(Posix):
// dfmt on

import gear.event.selector.Selector;
import gear.Functions;
import gear.net.channel.AbstractSocketChannel;
import gear.net.channel.ChannelTask;
import gear.net.channel.Types;
import gear.net.IoError;
import gear.logging.ConsoleLogger;
import gear.system.Error;
import gear.util.worker;

import nbuff;

import std.format;
import std.socket;

import core.atomic;
import core.stdc.errno;
import core.stdc.string;

import core.sys.posix.sys.socket : accept;
import core.sys.posix.unistd;

/**
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {
    protected size_t _bufferSize = 4096;
    private NbuffChunk _writeBytes;
    private ChannelTask _task = null;
    size_t _receivedLen = 0;

    /**
    * Warning: The received data is stored a inner buffer. For a data safe,
    * you would make a copy of it.
    */
    protected DataReceivedHandler dataReceivedHandler;
    protected DataSendedHandler dataSendedHandler;
    protected SimpleEventHandler disconnectionHandler;
    protected SimpleActionHandler dataWriteDoneHandler;

    protected AddressFamily _family;
    // protected Buffer _bufferForRead;
    // protected WritingBufferQueue _writeQueue;
    protected Nbuff _senddingBuffer;
    protected bool _isWriteCancelling = false;

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        this._family = family;
        _bufferSize = bufferSize;
        super(loop, ChannelType.TCP);
        setFlag(ChannelFlag.Read, true);
        setFlag(ChannelFlag.Write, true);
        setFlag(ChannelFlag.ETMode, true);
    }

    abstract bool IsClient();
    abstract bool IsConnected() nothrow;
    abstract protected void OnDisconnected();

    private void onDataReceived(NbuffChunk bytes) {
        if(taskWorker is null) {
            // TODO: Tasks pending completion -@zhangxueping at 2021-03-09T09:59:00+08:00
            // Using memory pool
            if (dataReceivedHandler !is null) {
                dataReceivedHandler(bytes);
            }
        } else {
            ChannelTask task = _task;

            // FIXME: Needing refactor or cleanup -@zhangxueping at 2021-02-05T09:18:02+08:00
            // More tests needed
            if(task is null || task.IsFinishing()) {
                task = CreateChannelTask();
                _task = task;

            } else {
                version(GEAR_METRIC) {
                    Warningf("Request peeding... Task status: %s", task.Status);
                }
            }

            task.put(bytes);
        }
    }

    private ChannelTask CreateChannelTask() {
        ChannelTask task = new ChannelTask();
        task.dataReceivedHandler = dataReceivedHandler;
        taskWorker.put(task);
        return task;
    }

    /**
     *
     */
    protected bool TryRead() {
        bool isDone = true;
        this.ClearError();

        // TODO: Tasks pending completion -@zhangxueping at 2021-03-09T09:59:00+08:00
        // Using memory pool        
   
        // auto readBuffer = Buffer.Get(_bufferSize);
        // auto readBufferSpace =  readBuffer.data();
        // NbuffChunk buffer = Nbuff.get(_bufferSize);
        auto buffer = Nbuff.get(_bufferSize);
        // ubyte[] readData = buffer.AsArray();

        // TODO : loop read data
        ptrdiff_t len = read(this.handle, cast(void*)buffer.ptr, _bufferSize);

        // ubyte[] rb = new ubyte[BufferSize];
        // ptrdiff_t len = read(this.handle, cast(void*) rb.ptr, rb.length);
        version (GEAR_IO_DEBUG) Tracef("reading[fd=%d]: %d bytes", this.handle, len);

        if (len > 0)
        {
            version(GEAR_IO_DEBUG)
            {
                if (len <= 32)
                    Infof("fd: %d, %d bytes: %(%02X %)", this.handle, len, buffer[0 .. len]);
                else
                    Infof("fd: %d, 32/%d bytes: %(%02X %)", this.handle, len, buffer[0 .. 32]);
            }

            // buffer.ReaderIndex(0);
            // buffer.WriterIndex(len);
            onDataReceived(NbuffChunk(buffer, len));

            // It's prossible that there are more data waitting for read in the read I/O space.
            if (len == _bufferSize) {
                version (GEAR_IO_DEBUG) Infof("Read buffer is full read %d bytes. Need to read again.", len);
                isDone = false;
            }
        }
        else if (len == Socket.ERROR)
        {
            // https://stackoverflow.com/questions/14595269/errno-35-eagain-returned-on-recv-call
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:06:13
            // check more Error status
            this._error = errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK;
            if (_error)
            {
                this._errorMessage = GetErrorMessage(errno);

                if(errno == ECONNRESET)
                {
                    // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                    OnDisconnected();
                    ErrorOccurred(ErrorCode.CONNECTIONEESET , "connection reset by peer");
                }
                else
                {
                    ErrorOccurred(ErrorCode.INTERRUPTED , "Error occurred on read");
                }
            }
        }
        else
        {
            version (GEAR_DEBUG) Infof("connection broken: %s, fd:%d", _remoteAddress.toString(), this.handle);

            OnDisconnected();
        }

        return isDone;
    }

    override protected void DoClose()
    {
        version (GEAR_IO_DEBUG) Infof("peer socket %s closing: fd=%d", this.RemoteAddress.toString(), this.handle);

        if(this.socket is null)
        {
            import core.sys.posix.unistd;
            core.sys.posix.unistd.close(this.handle);
        }
        else
        {
            this.socket.shutdown(SocketShutdown.BOTH);
            this.socket.close();
        }

        version (GEAR_IO_DEBUG) Infof("peer socket %s closed: fd=%d", this.RemoteAddress.toString, this.handle);

        Task task = _task;
        if(task !is null)
        {
            task.Stop();
        }
    }

    /**
     * Try to write a block of data.
     */
    protected ptrdiff_t TryWrite(const(ubyte)[] data) 
    {
        ClearError();
        // const nBytes = this.socket.send(data);
        version (GEAR_IO_DEBUG) Tracef("try to write: %d bytes, fd=%d", data.length, this.handle);

        const nBytes = write(this.handle, data.ptr, data.length);

        version (GEAR_IO_DEBUG)
            Tracef("actually written: %d / %d bytes, fd=%d", nBytes, data.length, this.handle);

        if (nBytes > 0) {
            return nBytes;
        }

        if (nBytes == Socket.ERROR) {
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:07:38
            // check more Error status
            // EPIPE/Broken pipe:
            // https://github.com/angrave/SystemProgramming/wiki/Networking%2C-Part-7%3A-Nonblocking-I-O%2C-select%28%29%2C-and-epoll

            if(errno == EAGAIN) {
                version (GEAR_IO_DEBUG) {
                    Warningf("Warning on write: fd=%d, errno=%d, message=%s", this.handle,
                        errno, GetErrorMessage(errno));
                }
            } else if(errno == EINTR || errno == EWOULDBLOCK) {
                // https://stackoverflow.com/questions/38964745/can-a-socket-become-writeable-after-an-ewouldblock-but-before-an-epoll-wait
                debug Warningf("Warning on write: fd=%d, errno=%d, message=%s", this.handle,
                        errno, GetErrorMessage(errno));
                // eventLoop.update(this);
            } else {
                this._error = true;
                this._errorMessage = GetErrorMessage(errno);
                if(errno == ECONNRESET) {
                    // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                    OnDisconnected();
                    ErrorOccurred(ErrorCode.CONNECTIONEESET , "connection reset by peer");
                } else if(errno == EPIPE) {
                    // https://stackoverflow.com/questions/6824265/sigpipe-broken-pipe
                    // Handle SIGPIPE signal
                    OnDisconnected();
                    ErrorOccurred(ErrorCode.BROKENPIPE , "Broken pipe detected!");
                }

            }
        } else {
            version (GEAR_DEBUG) {
                Warningf("nBytes=%d, message: %s", nBytes, lastSocketError());
                assert(false, "Undefined behavior!");
            } else {
                this._error = true;
            }
        }

        return 0;
    }

    private bool TryNextWrite(NbuffChunk buffer) {
        const(ubyte)[] data = cast(const(ubyte)[])buffer.data;
        version (GEAR_IO_DEBUG) {
            Tracef("writting from a buffer [fd=%d], %d bytes, buffer: %s",
                this.handle, data.length, buffer.data.ptr);
        }

        ptrdiff_t remaining = data.length;
        if(data.length == 0)
            return true;

        while(remaining > 0 && !_error && !IsClosing() && !_isWriteCancelling) {
            ptrdiff_t nBytes = TryWrite(data);
            version (GEAR_IO_DEBUG)
            {
                Tracef("write out once: fd=%d, %d / %d bytes, remaining: %d buffer: %s",
                    this.handle, nBytes, data.length, remaining, buffer.AsArray.ptr);
            }

            if (nBytes > 0) {
                remaining -= nBytes;
                data = data[nBytes .. $];
            }
        }

        version (GEAR_IO_DEBUG) {
            if(remaining == 0) {
                    Tracef("A buffer is written out. fd=%d", this.handle);
                return true;
            } else {
                Warningf("Writing cancelled or an Error ocurred. fd=%d", this.handle);
                return false;
            }
        } else {
            return remaining == 0;
        }
    }

    void ResetWriteStatus() {
        // if(_writeQueue !is null)
        //     _writeQueue.Clear();
        if(!_senddingBuffer.empty())
            _senddingBuffer.clear();
        atomicStore(_isWritting, false);
        _isWriteCancelling = false;
    }

    /**
     * Should be thread-safe.
     */
    override void OnWrite() {
        version (GEAR_IO_DEBUG)
        {
            Tracef("checking status, isWritting: %s, writeBytes: %s",
                _isWritting, _writeBytes.empty() ? "null" : cast(string)_writeBytes.data());
        }

        if(!_isWritting) {
            version (GEAR_IO_DEBUG)
            Infof("No data needs to be written out. fd=%d", this.handle);
            return;
        }

        if(IsClosing() && _isWriteCancelling) {
            version (GEAR_DEBUG) Infof("Write cancelled or closed, fd=%d", this.handle);
            ResetWriteStatus();
            return;
        }

        // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-04-24T14:26:45+08:00
        // More tests are needed
        // keep thread-safe here
        if(!cas(&_isBusyWritting, false, true)) {
            // version (GEAR_IO_DEBUG)
            version(GEAR_DEBUG) Warningf("busy writing. fd=%d", this.handle);
            return;
        }

        scope(exit) {
            _isBusyWritting = false;
        }

        if(!_writeBytes.empty()) {
            if(TryNextWrite(_writeBytes)) {
                _writeBytes.popBackN(_writeBytes.length);
            } else {
                version (GEAR_IO_DEBUG)
                {
                    Infof("waiting to try again... fd=%d, writeBytes: %s",
                        this.handle, cast(string)_writeBytes.AsArray);
                }
                // eventLoop.update(this);
                return;
            }
            version (GEAR_IO_DEBUG)
                Tracef("running here, fd=%d", this.handle);
        }

        if(CheckAllWriteDone()) {
            return;
        }

        version (GEAR_IO_DEBUG) {
            Tracef("start to write [fd=%d], writeBytes %s empty", this.handle, _writeBytes.empty() ? "is" : "is not");
        }

        _writeBytes = _senddingBuffer.frontChunk();
        _senddingBuffer.popChunk();
        if(!_writeBytes.empty()) {
            if(TryNextWrite(_writeBytes)) {
                _writeBytes.popBackN(_writeBytes.length);
                CheckAllWriteDone();
            } else {
            version (GEAR_IO_DEBUG)
                Infof("waiting to try again: fd=%d, writeBytes: %s", this.handle, cast(string)_writeBytes.AsArray);

                // eventLoop.update(this);
            }
            version (GEAR_IO_DEBUG) {
                Warningf("running here, fd=%d", this.handle);
            }
        }
    }
    private shared bool _isBusyWritting = false;

    protected bool CheckAllWriteDone() {
        version (GEAR_IO_DEBUG) {
            import std.conv;
            Tracef("checking remaining: fd=%d, writeQueue empty: %s", this.handle,
               _senddingBuffer.empty() ||  _senddingBuffer.empty().to!string());
        }

        if(_senddingBuffer.empty()) {
            ResetWriteStatus();
            version (GEAR_IO_DEBUG)
                Infof("All data are written out: fd=%d", this.handle);
            if(dataWriteDoneHandler !is null)
                dataWriteDoneHandler(this);
            return true;
        }

        return false;
    }

    protected void InitializeWriteQueue() {
        // if (_writeQueue is null) {
        //     _writeQueue = new WritingBufferQueue();
        // }
    }

    protected bool DoConnect(Address addr) {
        try {
            this.socket.connect(addr);
        } catch (SocketOSException e) {
            gear.logging.ConsoleLogger.Error(e.msg);
            version(GEAR_DEBUG) error(e);
            return false;
        }
        return true;
    }

    void CancelWrite() {
        _isWriteCancelling = true;
    }

    bool isWriteCancelling() {
        return _isWriteCancelling;
    }

    DataReceivedHandler GetDataReceivedHandler() {
        return dataReceivedHandler;
    }

}
