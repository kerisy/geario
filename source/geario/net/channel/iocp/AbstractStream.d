module geario.net.channel.iocp.AbstractStream;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import geario.event.selector.Selector;
import geario.net.channel.AbstractSocketChannel;
import geario.net.channel.ChannelTask;
import geario.net.channel.Types;
import geario.net.channel.iocp.Common;
import geario.logging;
import geario.Functions;
import geario.event.selector.IOCP;
import geario.system.Error;
import geario.util.ThreadHelper;
import geario.util.worker;
import nbuff;
import core.atomic;
import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;
import std.format;
import std.socket;
import std.string;
import core.stdc.string;

/**
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {

    // data event handlers
    
    /**
    * Warning: The received data is stored a inner buffer. For a data safe, 
    * you would make a copy of it. 
    */
    protected DataReceivedHandler dataReceivedHandler;
    protected DataSendedHandler dataSendedHandler;
    protected SimpleActionHandler dataWriteDoneHandler;

    protected NbuffChunk _bufferForRead;
    protected AddressFamily _family;

    private size_t _bufferSize = 4096;
    private ChannelTask _task = null;
    

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        _bufferSize = bufferSize;
        super(loop, ChannelType.TCP);
        // setFlag(ChannelFlag.Read, true);
        // setFlag(ChannelFlag.Write, true);

        // version (GEAR_IO_DEBUG)
        //     Trace("Buffer size: ", bufferSize);
        // _readBuffer = new ubyte[bufferSize];
        // _readBytes = Nbuff.get(_bufferSize);
        //_bufferForRead = BufferUtils.allocate(bufferSize);

        //_readBuffer = cast(ubyte[])_bufferForRead.toString();
        // _writeQueue = new WritingBufferQueue();
        // this.socket = new TcpSocket(family);

        loadWinsockExtension(this.handle);
    }

    mixin CheckIocpError;

    abstract bool IsClient();

    override void OnRead() {
        version (GEAR_IO_DEBUG)
            Trace("ready to read");
        super.OnRead();
    }

    /**
     * Should be thread-safe.
     */
    override void OnWrite() {  
        version (GEAR_IO_DEBUG)
            log.trace("checking write status, isWritting: %s, writeBytes: %s", _isWritting, writeBytes is null);

        //if(!_isWritting){
        //    version (GEAR_IO_DEBUG) log.info("No data to write out. fd=%d", this.handle);
        //    return;
        //}

        if(IsClosing() && _isWriteCancelling) {
            version (GEAR_IO_DEBUG) log.info("Write cancelled, fd=%d", this.handle);
            ResetWriteStatus();
            return;
        }
        TryNextBufferWrite();
    }
    
    protected override void OnClose() {
        _isWritting = false;
        ResetWriteStatus();
        if(this._socket is null) {
            import core.sys.windows.winsock2;
            .closesocket(this.handle);
        } else {
            // FIXME: Needing refactor or cleanup -@Administrator at 2019/8/9 1:20:27 pm
            //
            //while(!_isSingleWriteBusy)
            //{
                this._socket.shutdown(SocketShutdown.BOTH);
                this._socket.close();
            //}
        }
        super.OnClose();
    }

    void BeginRead() {
        // https://docs.microsoft.com/en-us/windows/desktop/api/winsock2/nf-winsock2-wsarecv
        ///  _isSingleWriteBusy = true;
        auto b = Nbuff.get(_bufferSize);

        _readBuffer = b.data();

        WSABUF _dataReadBuffer;
        _dataReadBuffer.len = cast(uint) _readBuffer.length;
        _dataReadBuffer.buf = cast(char*) _readBuffer.ptr;
        memset( &_iocpread.overlapped , 0, _iocpread.overlapped.sizeof );
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.read;
        DWORD dwReceived = 0;
        DWORD dwFlags = 0;
        version (GEAR_IO_DEBUG)
            log.trace("start receiving [fd=%d] ", this.socket.handle);
        // _isSingleWriteBusy = true;
        int nRet = WSARecv(cast(SOCKET) this.socket.handle, &_dataReadBuffer, 1u, &dwReceived, &dwFlags, &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        if (nRet == SOCKET_ERROR && (GetLastError() != ERROR_IO_PENDING)) {
            _isSingleWriteBusy = false;
            Close();
        }
        //checkErro(nRet, SOCKET_ERROR);
    }

    protected bool DoConnect(Address addr) {
        Address binded = CreateAddress(this.socket.addressFamily);
        _isSingleWriteBusy = true;
        this.socket.bind(binded);
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.connect;

        import std.datetime.stopwatch;
        auto sw = StopWatch(AutoStart.yes);
        sw.start();
        scope(exit) {
            sw.stop();
        }

        // https://docs.microsoft.com/en-us/windows/win32/api/mswsock/nc-mswsock-lpfn_connectex
        int nRet = ConnectEx(cast(SOCKET) this.socket.handle(), cast(SOCKADDR*) addr.name(), 
            addr.nameLen(), null, 0, null, &_iocpread.overlapped);
        checkErro(nRet, SOCKET_ERROR);

        if(this._error) 
            return false;

        // https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-getsockopt
        int seconds = 0;
        int bytes = seconds.sizeof;
        int iResult = 0;

        CHECK: 
        iResult = getsockopt(cast(SOCKET) this.socket.handle(), SOL_SOCKET, SO_CONNECT_TIME,
                            cast(void*)&seconds, cast(PINT)&bytes);

        bool result = false;
        if ( iResult != NO_ERROR ) {
            DWORD dwLastError = WSAGetLastError();
            log.warning("getsockopt(SO_CONNECT_TIME) failed with Error: code=%d, message=%s", 
                dwLastError, GetErrorMessage(dwLastError));
        } else {
            if (seconds == 0xFFFFFFFF) {
                version(GEAR_IO_DEBUG) log.warning("Connection not established yet (destination: %s).", addr);
                // so to check again
                goto CHECK;
            } else {
                result = true;
                version(GEAR_IO_DEBUG) {
                    //
                    log.info("Connection has been established in %d msecs, destination: %s", sw.peek.total!"msecs", addr);
                }
                // https://docs.microsoft.com/en-us/windows/win32/winsock/sol-socket-socket-options
                enum SO_UPDATE_CONNECT_CONTEXT = 0x7010;
                iResult = setsockopt(cast(SOCKET) this.socket.handle(), SOL_SOCKET, 
                    SO_UPDATE_CONNECT_CONTEXT, NULL, 0 );
            }
        }
        
        return result;
    }

    private uint DoWrite(const(ubyte)[] data) {
        DWORD dwSent = 0;//cast(DWORD)data.length;
        DWORD dwFlags = 0;

        memset(&_iocpwrite.overlapped , 0 ,_iocpwrite.overlapped.sizeof );
        _iocpwrite.channel = this;
        _iocpwrite.operation = IocpOperation.write;
        // log.trace("To write %d bytes, fd=%d", data.length, this.socket.handle());
        version (GEAR_IO_DEBUG) {
            size_t bufferLength = data.length;
            log.trace("To write %d bytes", bufferLength);
            if (bufferLength > 32)
                log.trace("%(%02X %) ...", data[0 .. 32]);
            else
                log.trace("%s", data);
        }
        // size_t bufferLength = data.length;
        //     log.trace("To write %d bytes", bufferLength);
        //     log.trace("%s", data);
        WSABUF _dataWriteBuffer;

        //char[] bf = new char[data.length];
        //memcpy(bf.ptr,data.ptr,data.length);
        //_dataWriteBuffer.buf =  bf.ptr;
        _dataWriteBuffer.buf = cast(char*) data.ptr;
        _dataWriteBuffer.len = cast(uint) data.length;
        // _isSingleWriteBusy = true;
        int nRet = WSASend( cast(SOCKET) this.socket.handle(), &_dataWriteBuffer, 1, &dwSent,
        dwFlags, &_iocpwrite.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
        // if (nRet != NO_ERROR && (GetLastError() != ERROR_IO_PENDING))
        // {
        //     _isSingleWriteBusy = false;
        //     // Close();
        // }

        checkErro( nRet, SOCKET_ERROR);

        // FIXME: Needing refactor or cleanup -@Administrator at 2019/8/9 12:18:20 pm
        // Keep this to prevent the buffer corrupted. Why?
        version (GEAR_IO_DEBUG) {
            log.trace("sent: %d / %d bytes, fd=%d", dwSent, bufferLength, this.handle);
        }

        if (this.IsError) {
            log.error("Socket Error on write: fd=%d, message=%s", this.handle, this.ErrorMessage);
            this.Close();
        }

        return dwSent;
    }

    protected void DoRead() {
        //_isSingleWriteBusy = false;
        this.ClearError();
        version (GEAR_IO_DEBUG)
            log.trace("start reading: %d nbytes", this.readLen);

        if (readLen > 0) {
            // import std.stdio;
            // writefln("length=%d, data: %(%02X %)", readLen, _readBuffer[0 .. readLen]);
            HandleReceivedData(readLen);

            // Go on reading
            this.BeginRead();

        } else if (readLen == 0) {
            version (GEAR_IO_DEBUG) {
                if (_remoteAddress !is null)
                    log.warning("connection broken: %s", _remoteAddress.toString());
            }
            OnDisconnected();
            // if (_isClosed)
            //     this.Close();
        } else {
            version (GEAR_IO_DEBUG) {
                log.warning("undefined behavior on thread %d", GetTid());
            } else {
                this._error = true;
                this._errorMessage = "undefined behavior on thread";
            }
        }
    }

    private void HandleReceivedData(ptrdiff_t len) {
        version (GEAR_IO_DEBUG)
            log.trace("reading done: %d nbytes", readLen);

        if (dataReceivedHandler is null) 
            return;

        // _bufferForRead.limit(cast(int)readLen);
        // _bufferForRead.position(0);
        // dataReceivedHandler(_bufferForRead);

        // Bytes bufferCopy;
        import std.algorithm : copy;
        auto buffer = Nbuff.get(len);
        copy((cast(string)_readBuffer[0 .. len]).representation, buffer.data);

        NbuffChunk bytes = NbuffChunk(buffer, len);

        // bufferCopy.opAssign(_bufferForRead);
        if(taskWorker is null) {
            dataReceivedHandler(bytes);
        } else {
            ChannelTask task = _task;

            // FIXME: Needing refactor or cleanup -@zhangxueping at 2021-02-05T09:18:02+08:00
            // More tests needed
            if(task is null || task.IsFinishing()) {
                task = CreateChannelTask();
                _task = task;

            } else {
                version(GEAR_METRIC) {
                    log.warning("Request peeding... Task status: %s", task.status);
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

    // try to write a block of data directly
    protected size_t TryWrite(const ubyte[] data) {        
        version (GEAR_IO_DEBUG)
            log.trace("start to write, total=%d bytes, fd=%d", data.length, this.handle);
        ClearError();
        size_t nBytes;
        //scope(exit) {
        //    _isSingleWriteBusy = false;
        //}
        if (!_isSingleWriteBusy)
        {
             nBytes = DoWrite(data);
        }

        return nBytes;
    }

    // try to write a block of data from the write queue
    private void TryNextBufferWrite() {
        if(CheckAllWriteDone()){
            _isSingleWriteBusy = false;
            // if (!IsClient())
            // {
            //     this.BeginRead();
            // }
            return;
        } 
        
        // keep thread-safe here
        //if(!cas(&_isSingleWriteBusy, false, true)) {
        //    version (GEAR_IO_DEBUG) log.warning("busy writing. fd=%d", this.handle);
        //    return;
        //}

        //scope(exit) {
        //    _isSingleWriteBusy = false;
        //}

        ClearError();

        // bool haveBuffer = _writeQueue.TryDequeue(writeBytes);
        writeBytes = _senddingBuffer.frontChunk();
        _senddingBuffer.popChunk();
        WriteBufferRemaining();
    }

    private void WriteBufferRemaining() {
        if ( writeBytes.empty() )
        {
            return;
        }
        const(ubyte)[] data = cast(const(ubyte)[])writeBytes.data();

        size_t nBytes = DoWrite(data);

        version (GEAR_IO_DEBUG)
            log.trace("written data: %d bytes, fd=%d", nBytes, this.handle);
        if(nBytes == data.length) {
            writeBytes.popBackN(writeBytes.length);
        } else if (nBytes > 0) { 
            writeBytes.popFrontN(nBytes);
            version (GEAR_IO_DEBUG)
                log.warning("remaining data: %d / %d, fd=%d", data.length - nBytes, data.length, this.handle);
        } else { 
            version (GEAR_IO_DEBUG)
            log.warning("I/O busy: writing. fd=%d", this.handle);
        }   
    }
    
    protected bool CheckAllWriteDone()
    {
        if ( _senddingBuffer.empty() && writeBytes.empty() )
        {
            ResetWriteStatus();

            version (GEAR_IO_DEBUG)
                log.trace("All data are written out. fd=%d", this.handle);

            if(dataWriteDoneHandler !is null)
                dataWriteDoneHandler(this);

            return true;
        }

        return false;
    }
    
    void ResetWriteStatus()
    {
        if(!_senddingBuffer.empty())
            _senddingBuffer.clear();

        _isWritting = false;
        _isWriteCancelling = false;
        sendDataBuffer = null;
        sendDataBackupBuffer = null;
        if (!writeBytes.empty())
            writeBytes.popBackN(writeBytes.length);
        _isSingleWriteBusy = false;
    }

    /**
     * Called by selector after data sent
     * Note: It's only for IOCP selector: 
    */
    void OnWriteDone(size_t nBytes) {
        version (GEAR_IO_DEBUG) {
            log.trace("write done once: %d bytes, isWritting: %s, writeBytes: %s, fd=%d",
                 nBytes, _isWritting, writeBytes is null, this.handle);
        }
        //if (_isWriteCancelling) {
        //    version (GEAR_IO_DEBUG) log.trace("write cancelled.");
        //    ResetWriteStatus();
        //    return;
        //}


        //while(_isSingleWriteBusy) {
        //    version(GEAR_IO_DEBUG)
        //    Info("waiting for last writting get finished...");
        //}

        version (GEAR_IO_DEBUG) {
            log.trace("write done once: %d bytes, isWritting: %s, writeBytes: %s, fd=%d",
                 nBytes, _isWritting, writeBytes is null, this.handle);
        }

        if (!writeBytes.empty()) {
            version (GEAR_IO_DEBUG) log.trace("try to write the remaining in buffer.");
            WriteBufferRemaining();
        }  else {
            version (GEAR_IO_DEBUG) log.trace("try to write next buffer.");
            TryNextBufferWrite();
        }
    }

    private void NotifyDataWrittenDone() {
        if(dataWriteDoneHandler !is null && _senddingBuffer.empty) {
            dataWriteDoneHandler(this);
        }
    }
    
    DataReceivedHandler GetDataReceivedHandler() {
        return dataReceivedHandler;
    }

    void CancelWrite() {
        _isWriteCancelling = true;
    }

    abstract bool IsConnected() nothrow;
    abstract protected void OnDisconnected();

    protected void InitializeWriteQueue() {
        // if (_writeQueue is null) {
        //     _writeQueue = new WritingBufferQueue();
        // }
    }

    SimpleEventHandler disconnectionHandler;
    
    // protected WritingBufferQueue _writeQueue;
    protected Nbuff _senddingBuffer;
    protected bool _isWriteCancelling = false;
    private  bool _isSingleWriteBusy = false; // keep a single I/O write operation atomic
    private NbuffChunk _readBytes;
    private ubyte[] _readBuffer;
    private const(ubyte)[] sendDataBuffer;
    private const(ubyte)[] sendDataBackupBuffer;
    private NbuffChunk writeBytes; 

    private IocpContext _iocpread;
    private IocpContext _iocpwrite;
}
