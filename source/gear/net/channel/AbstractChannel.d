module gear.net.channel.AbstractChannel;

import gear.event.selector.Selector;
import gear.net.channel.Common;
import gear.net.IoError;
import gear.logging.ConsoleLogger;
import gear.util.worker;

import core.atomic;
import std.bitmanip;
import std.socket : socket_t;


/**
 *
 */
abstract class AbstractChannel : Channel {
    socket_t handle = socket_t.init;
    ErrorEventHandler errorHandler;
    
    Worker taskWorker = null;

    protected bool _isRegistered = false;
    private shared bool _isClosing = false;
    protected shared bool _isClosed = false;

    this(Selector loop, ChannelType type) {
        this._inLoop = loop;
        _type = type;
        _flags = BitArray([false, false, false, false, false, false, false,
                false, false, false, false, false, false, false, false, false]);
    }

    /**
     *
     */
    bool IsRegistered() {
        return _isRegistered;
    }

    /**
     *
     */
    bool IsClosing() {
        return _isClosing;
    }

    /**
     *
     */
    bool IsClosed() {
        return _isClosed;
    }

    /**
     *
     */
    void Close() {
        if (!_isClosed && cas(&_isClosing, false, true) ) {
            version (GEAR_IO_DEBUG_MORE)
                Tracef("channel[fd=%d] closing...", this.handle);

            // closing
            DoClose(); // close
            _isClosed = true;

            // closed
            OnClose(); 
            _isClosing = false;
            version (GEAR_IO_DEBUG)
                Tracef("channel[fd=%d] closed", this.handle);

        } else {
            version (GEAR_IO_DEBUG) {
                Warningf("The channel[fd=%d] has already been closed (%s) or closing (%s)",
                 this.handle, _isClosed, _isClosing);
            }
        }
    }

    protected void DoClose() {

    }

     void OnClose() {
        version (GEAR_IO_DEBUG)
            Tracef("onClose [fd=%d]...", this.handle);
        _isRegistered = false;
        _inLoop.Deregister(this);
        Clear();

        version (GEAR_IO_DEBUG_MORE)
            Tracef("onClose done [fd=%d]...", this.handle);

        _isClosed = true;
    }

    protected void ErrorOccurred(ErrorCode code, string msg) {
        debug Warningf("isRegistered: %s, isClosed: %s, msg=%s", _isRegistered, _isClosed, msg);
        if (errorHandler !is null) {
            errorHandler(new IoError(code, msg));
        }
    }

    void OnRead() {
        assert(false, "not implemented");
    }

    void OnWrite() {
        assert(false, "not implemented");
    }

    final bool HasFlag(ChannelFlag index) {
        return _flags[index];
    }

    @property ChannelType Type() {
        return _type;
    }

    @property Selector eventLoop() {
        return _inLoop;
    }

    void SetNext(AbstractChannel next) {
        if (next is this)
            return; // Can't set to self
        next._next = _next;
        next._priv = this;
        if (_next)
            _next._priv = next;
        this._next = next;
    }

    void Clear() {
        if (_priv)
            _priv._next = _next;
        if (_next)
            _next._priv = _priv;
        _next = null;
        _priv = null;
    }

    mixin OverrideErro;

protected:
    final void setFlag(ChannelFlag index, bool enable) {
        _flags[index] = enable;
    }

    Selector _inLoop;

private:
    BitArray _flags;
    ChannelType _type;

    AbstractChannel _priv;
    AbstractChannel _next;
}



/**
    https://stackoverflow.com/questions/40361869/how-to-wake-up-epoll-wait-before-any-event-happened
*/
class EventChannel : AbstractChannel {
    this(Selector loop) {
        super(loop, ChannelType.Event);
    }

    abstract void trigger();
    // override void Close() {
    //     if(_isClosing)
    //         return;
    //     _isClosing = true;
    //     version (GEAR_DEBUG) Tracef("closing [fd=%d]...", this.handle);

    //     if(isBusy) {
    //         import std.parallelism;
    //         version (GEAR_DEBUG) Warning("Close operation delayed");
    //         auto theTask = task(() {
    //             while(isBusy) {
    //                 version (GEAR_DEBUG) Infof("waitting for idle [fd=%d]...", this.handle);
    //                 // Thread.sleep(20.msecs);
    //             }
    //             super.Close();
    //         });
    //         taskPool.put(theTask);
    //     } else {
    //         super.Close();
    //     }
    // }
}

mixin template OverrideErro() {
    bool IsError() {
        return _error;
    }

    deprecated("Using errorMessage instead.")
    alias erroString = ErrorMessage;

    string ErrorMessage() {
        return _errorMessage;
    }

    void ClearError() {
        _error = false;
        _errorMessage = "";
    }

    bool _error = false;
    string _errorMessage;
}
