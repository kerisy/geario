/*
 * Gear - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.util.worker.WorkerThread;

import gear.util.Closeable;
import gear.util.ResoureManager;
import gear.util.worker.Task;
import gear.util.worker.Worker;

import gear.logging.ConsoleLogger;

import core.atomic;
import core.memory;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.conv;



enum WorkerThreadState {
    Idle,
    Busy, // occupied
    Stopped
}

bool InWorkerThread() {
    WorkerThread th = cast(WorkerThread) Thread.getThis();
    return th !is null;
}

/**
 *
 */
class WorkerThread : Thread {

    private shared WorkerThreadState _state;
    private size_t _index;
    private Task _task;
    private Duration _timeout;

    private Condition _condition;
    private Mutex _mutex;

    this(size_t index, Duration timeout = 5.seconds, size_t stackSize = 0) {
        _index = index;
        _timeout = timeout;
        _state = WorkerThreadState.Idle;
        _mutex = new Mutex();
        _condition = new Condition(_mutex);
        this.name = "WorkerThread-" ~ _index.to!string();
        super(&Run, stackSize);
    }

    void Stop() {
        _state = WorkerThreadState.Stopped;
    }

    bool IsBusy() {
        return _state == WorkerThreadState.Busy;
    }
    
    bool IsIdle() {
        return _state == WorkerThreadState.Idle;
    }

    WorkerThreadState State() {
        return _state;
    }

    size_t Index() {
        return _index;
    }

    Task task() {
        return _task;
    }

    bool Attatch(Task task) {
        assert(task !is null);
        bool r = cas(&_state, WorkerThreadState.Idle, WorkerThreadState.Busy);

        if (r) {
            version(GEAR_IO_DEBUG) {
                Infof("attatching task %d with thread %s", task.id, this.name);
            }

            _mutex.lock();
            scope (exit) {
                _mutex.unlock();
            }
            _task = task;
            _condition.notify();
            
        } else {
            Warningf("%s is unavailable. state: %s", this.name(), _state);
        }

        return r;
    }

    private void Run() nothrow {
        while (_state != WorkerThreadState.Stopped) {

            scope (exit) {
                version (GEAR_IO_DEBUG) {
                    Tracef("%s Done. state: %s", this.name(), _state);
                }

                CollectResoure();
                _task = null;
                bool r = cas(&_state, WorkerThreadState.Busy, WorkerThreadState.Idle);
                if(!r) {
                    Warningf("Failed to set thread %s to Idle, its state is %s", this.name, _state);
                }
            } 

            try {
                DoRun();
            } catch (Throwable ex) {
                Warning(ex);
            } 
        }
        
        version (GEAR_DEBUG) Tracef("%s Stopped. state: %s", this.name(), _state);
    }

    private bool _isWaiting = false;

    private void DoRun() {
        _mutex.lock();
        
        Task task = _task;
        while(task is null && _state != WorkerThreadState.Stopped) {
            bool r = _condition.wait(_timeout);
            task = _task;

            version(GEAR_IO_DEBUG) {
                if(!r && _state == WorkerThreadState.Busy) {
                    if(task is null) {
                        Warningf("No task attatched on a busy thread %s in %s, task: %s", this.name, _timeout);
                    } else {
                        Warningf("more tests need for this status, thread %s in %s", this.name, _timeout);
                    }
                }
            }
        }

        _mutex.unlock();

        if(task !is null) {
            version(GEAR_IO_DEBUG) {
                Tracef("Try to exeucte task %d in thread %s, its status: %s", task.id, this.name, task.Status);
            }
            task.Execute();
        }
    }
}
