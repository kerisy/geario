module gear.event.selector.Selector;

import gear.Exceptions;
import gear.Functions;
import gear.net.channel.AbstractChannel;
import gear.net.channel.Common;
import gear.logging.ConsoleLogger;
import gear.util.worker;

import core.atomic;
import core.memory;
import core.thread;


/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/
abstract class Selector {

    private shared bool _running = false;
    private shared bool _isStopping = false;
    private bool _isReady;
    protected size_t _id;
    protected size_t divider;
    private Worker _taskWorker;
    // protected AbstractChannel[] channels;
    protected long idleTime = -1; // in millisecond
    protected int fd;

    private long timeout = -1; // in millisecond
    private Thread _thread;

    private SimpleEventHandler _startedHandler;
    private SimpleEventHandler _stoppeddHandler;

    this(size_t id, size_t divider, Worker worker = null, size_t maxChannels = 1500) {
        _id = id;
        _taskWorker = worker;
        this.divider = divider;
        // channels = new AbstractChannel[maxChannels];
    }

    size_t GetId() {
        return _id;
    }

    Worker worker() {
        return _taskWorker;
    }

    bool IsReady() {
        return _isReady;
    }


    /**
     * Tells whether or not this selector is running.
     *
     * @return <tt>true</tt> if, and only if, this selector is running
     */
    bool IsRuning() {
        return _running;
    }

    alias isOpen = IsRuning;

    bool IsStopping() {
        return _isStopping;
    }

    bool Register(AbstractChannel channel) {
        assert(channel !is null);
        channel.taskWorker = _taskWorker;
        void* context = cast(void*)channel;
        GC.addRoot(context);
        GC.setAttr(cast(void*)context, GC.BlkAttr.NO_MOVE);
        version (GEAR_IO_DEBUG) {
            int infd = cast(int) channel.handle;
            Tracef("Register channel@%s: fd=%d, selector: %d", context, infd, GetId());
        }        
        return true;
    }

    bool Deregister(AbstractChannel channel) {
        channel.taskWorker = null;
        void* context = cast(void*)channel;
        GC.removeRoot(context);
        GC.clrAttr(context, GC.BlkAttr.NO_MOVE);
        version(GEAR_IO_DEBUG) {
            size_t fd = cast(size_t) channel.handle;
            Infof("The channel@%s has been deregistered: fd=%d, selector: %d", context, fd, GetId());
        }        
        return true;
    }

    protected abstract int DoSelect(long timeout);

    /**
        timeout: in millisecond
    */
    void Run(long timeout = -1) {
        this.timeout = timeout;
        DoRun();
    }

    /**
        timeout: in millisecond
    */
    void RunAsync(long timeout = -1, SimpleEventHandler handler = null) {
        if(_running) {
            version (GEAR_IO_DEBUG) Warningf("The current selector %d has being running already!", _id);
            return;
        }
        this.timeout = timeout;
        version (GEAR_IO_DEBUG) Trace("runAsync ...");
        Thread th = new Thread(() { 
            try {
                DoRun(handler); 
            } catch (Throwable t) {
                Warning(t.msg);
                version(GEAR_DEBUG) Warning(t.toString());
            }
        });
        // th.IsDaemon = true; // unstable
        th.start();
    }
    
    private void DoRun(SimpleEventHandler handler=null) {
        if(cas(&_running, false, true)) {
            version (GEAR_IO_DEBUG) Trace("running selector...");
            _thread = Thread.getThis();
            if(handler !is null) {
                handler();
            }
            OnLoop(timeout);
        } else {
            version (GEAR_DEBUG) Warningf("The current selector %d has being running already!", _id);
        }  
    }

    void Stop() {
        version (GEAR_IO_DEBUG)
            Tracef("Stopping selector %d. _running=%s, _isStopping=%s", _id, _running, _isStopping); 
        if(cas(&_isStopping, false, true)) {
            try {
                OnStop();
            } catch(Throwable t) {
                Warning(t.msg);
                version(GEAR_DEBUG) Warning(t);
            }
        }
    }

    protected void OnStop() {
        version (GEAR_IO_DEBUG) 
            Tracef("stopping.");
    }

    /**
        timeout: in millisecond
    */
    protected void OnLoop(long timeout = -1) {
        _isReady = true;
        idleTime = timeout;

        version (HAVE_IOCP) {
            DoSelect(timeout);
        } else {
            do {
                // version(GEAR_THREAD_DEBUG) Warningf("Threads: %d", Thread.getAll().length);
                DoSelect(timeout);
                // Infof("Selector rolled once. isRuning: %s", isRuning);
            } while (!_isStopping);
        }

        _isReady = false;
        _running = false;
        version(GEAR_IO_DEBUG) Infof("Selector %d exited.", _id);
        Dispose();
    }

    /**
        timeout: in millisecond
    */
    int Select(long timeout) {
        if (timeout < 0)
            throw new IllegalArgumentException("Negative timeout");
        return DoSelect((timeout == 0) ? -1 : timeout);
    }

    int Select() {
        return DoSelect(0);
    }

    int SelectNow() {
        return DoSelect(0);
    }

    void Dispose() {
        _thread = null;
        _startedHandler = null;
        _stoppeddHandler = null;
    }
    
    bool IsSelfThread() {
        return _thread is Thread.getThis();
    }
}
