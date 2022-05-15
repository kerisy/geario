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

module geario.util.Timer;

import geario.event;
import geario.event.timer;
import geario.logging.ConsoleLogger;
import geario.Exceptions;

import core.time;

/**
 * 
 */
class Timer : AbstractTimer {

    this(Selector loop) {
        super(loop);
        this.Interval = 1000;
    }

    this(Selector loop, size_t interval) {
        super(loop);
        this.Interval = interval;
    }

    this(Selector loop, Duration duration) {
        super(loop);
        this.Interval = duration;
    }

protected:

    override void OnRead() {
        bool canRead = true;
        while (canRead && _isRegistered) {
            canRead = readTimer((Object obj) {
                BaseTypeObject!uint tm = cast(BaseTypeObject!uint) obj;
                if (tm is null)
                    return;
                while (tm.data > 0) {
                    if (ticked !is null)
                        ticked(this);
                    tm.data--;
                }
            });
            if (this.IsError) {
                canRead = false;
                this.Close();
                geario.logging.ConsoleLogger.Error("the Timer Read is Error: ", this.ErrorMessage);
            }
        }
    }
}

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import std.datetime;
import std.exception;
import std.process;

import core.sys.windows.windows;
import core.thread;
import core.time;

/**
*/
abstract class AbstractNativeTimer : ITimer {
    protected bool _isActive = false;
    protected size_t _interval = 1000;

    /// Timer tick handler
    TickedEventHandler ticked;

    this() {
        this(1000);
    }

    this(size_t interval) {
        this.Interval = interval;
    }

    this(Duration duration) {
        this.Interval = duration;
    }

    /// 
    @property bool IsActive() {
        return _isActive;
    }

    /// in ms
    @property size_t Interval() {
        return _interval;
    }

    /// ditto
    @property ITimer Interval(size_t v) {
        _interval = v;
        return this;
    }

    /// ditto
    @property ITimer Interval(Duration duration) {
        _interval = cast(size_t) duration.total!("msecs");
        return this;
    }

    /// The handler will be handled in another thread.
    ITimer OnTick(TickedEventHandler handler) {
        this.ticked = handler;
        return this;
    }

    /// immediately: true to call first event immediately
    /// once: true to call timed event only once
    abstract void Start(bool immediately = false, bool once = false);
    void Start(uint interval) {
        this.Interval = interval;
        Start();
    }

    abstract void Stop();

    abstract void Reset(bool immediately = false, bool once = false);

    void Reset(size_t interval) {
        this.Interval = interval;
        Reset();
    }

    void Reset(Duration duration) {
        this.Interval = duration;
        Reset();
    }

    protected void OnTick() {
        // Trace("tick thread id: ", GetTid());
        if (ticked !is null)
            ticked(this);
    }
}

/**
* See_also:
*    https://www.codeproject.com/articles/146617/simple-c-timer-wrapper
*    https://msdn.microsoft.com/en-us/library/ms687003(v=vs.85)
*/
class NativeTimer : AbstractNativeTimer {
    protected HANDLE _handle = null;

    this() {
        super(1000);
    }

    this(size_t interval) {
        super(interval);
    }

    this(Duration duration) {
        super(duration);
    }

    /// immediately: true to call first event immediately
    /// once: true to call timed event only once
    override void Start(bool immediately = false, bool once = false) {
        version (GEAR_DEBUG)
            Trace("main thread id: ", thisThreadID());
        if (_isActive)
            return;
        BOOL r = CreateTimerQueueTimer(&_handle, null, &timerProc,
                cast(PVOID) this, immediately ? 0 : cast(int) Interval, once ? 0
                : cast(int) Interval, WT_EXECUTEINTIMERTHREAD);
        assert(r != 0);
        _isActive = true;
    }

    override void Stop() {
        if (_isActive) {
            DeleteTimerQueueTimer(null, _handle, null);
            _isActive = false;
        }
    }

    override void Reset(bool immediately = false, bool once = false) {
        if (_isActive) {
            assert(ChangeTimerQueueTimer(null, _handle, immediately ? 0
                    : cast(int) Interval, once ? 0 : cast(int) Interval) != 0);
        }
    }

    /// https://msdn.microsoft.com/en-us/library/ms687066(v=vs.85)
    extern (Windows) static private void timerProc(PVOID param, bool timerCalled) {
        version (GEAR_DEBUG)
            Trace("handler thread id: ", thisThreadID());
        AbstractNativeTimer timer = cast(AbstractNativeTimer)(param);
        assert(timer !is null);
        timer.OnTick();
    }
}
