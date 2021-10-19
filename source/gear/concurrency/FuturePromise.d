/*
 * Hunt - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.concurrency.FuturePromise;

import gear.concurrency.Future;
import gear.concurrency.Promise;

import gear.Exceptions;
import gear.logging.ConsoleLogger;

import core.atomic;
import core.thread;
import core.sync.mutex;
import core.sync.condition;

import std.format;
import std.datetime;

alias ThenHandler(T) = void delegate(T);

/**
 * 
 */
class FuturePromise(T) : Future!T, Promise!T {
    alias VoidHandler = void delegate();
    
    private shared bool _isCompleting = false;
    private bool _isCompleted = false;
    private Exception _cause;
    private string _id;
    private Mutex _waiterLocker;
    private Condition _waiterCondition;

    this() {
        _waiterLocker = new Mutex(this);
        _waiterCondition = new Condition(_waiterLocker);
    }

    string id() {
        return _id;
    }

    void id(string id) {
        _id = id;
    }

    ThenHandler!(Exception) _thenFailedHandler;

static if(is(T == void)) {
    VoidHandler _thenSucceededHandler;

    FuturePromise!R then(R)(R delegate() handler) {
        FuturePromise!R result = new FuturePromise!(R);
        _thenSucceededHandler = () {
            try {
                R r = handler();
                result.Succeeded(r);
            } catch(Exception ex) {
                Exception e = new Exception("then exception", ex);
                result.Failed(e);
            }
        };

        _thenFailedHandler = (Exception ex) {
            Exception e = new Exception("then exception", ex);
            result.Failed(e);
        };

        return result;
    }

    /**
     * TODO: 
     *     1) keep this operation atomic
     *     2) return a flag to indicate whether this option is successful.
     */
    void Succeeded() {
        if (cas(&_isCompleting, false, true)) {
            OnCompleted();
        } else {
            Warningf("This promise has been done, and can't be set again. cause: %s", 
                typeid(_cause));
        }
    }

} else {
    ThenHandler!(T) _thenSucceededHandler;

    FuturePromise!R then(R)(R delegate(T) handler) {
        FuturePromise!R result = new FuturePromise!(R);
        _thenSucceededHandler = (T t) {
            try {
                static if(is(R == void)) {
                    handler(t);
                    result.Succeeded();
                } else {
                    R r = handler(t);
                    result.Succeeded(r);
                }
            } catch(Exception ex) {
                Exception e = new Exception("then exception", ex);
                result.Failed(e);
            }
        };

        _thenFailedHandler = (Exception ex) {
            Exception e = new Exception("then exception", ex);
            result.Failed(e);
        };

        return result;
    }

    /**
     * TODO: 
     *     1) keep this operation atomic
     *     2) return a flag to indicate whether this option is successful.
     */
    void Succeeded(T result) {
        if (cas(&_isCompleting, false, true)) {
            _result = result;
            OnCompleted();
        } else {
            Warning("This promise has been done, and can't be set again.");
        }
    }
    private T _result;
}

    /**
     * TODO: 
     *     1) keep this operation atomic
     *     2) return a flag to indicate whether this option is successful.
     */
    void Failed(Exception cause) {
        if (cas(&_isCompleting, false, true)) {
            _cause = cause;    
            OnCompleted();        
        } else {
            Warningf("This promise has been done, and can't be set again. cause: %s", 
                typeid(_cause));
        }
    }

    bool Cancel(bool mayInterruptIfRunning) {
        if (cas(&_isCompleting, false, true)) {
            static if(!is(T == void)) {
                _result = T.init;
            }
            _cause = new CancellationException("");
            OnCompleted();
            return true;
        }
        return false;
    }

    private void OnCompleted() {
        _waiterLocker.lock();
        _isCompleted = true;
        scope(exit) {
            _waiterLocker.unlock();
        }
        
        _waiterCondition.notifyAll();

        if(_cause is null) {
            if(_thenSucceededHandler !is null) {
                static if(is(T == void)) {
                    _thenSucceededHandler();
                } else {
                    _thenSucceededHandler(_result);
                }
            }
        } else {
            if(_thenFailedHandler !is null) {
                _thenFailedHandler(_cause);
            }
        }
    }

    bool IsCancelled() {
        if (_isCompleted) {
            try {
                // _latch.await();
                // TODO: Tasks pending completion -@zhangxueping at 2019-12-26T15:18:42+08:00
                // 
            } catch (InterruptedException e) {
                throw new RuntimeException(e.msg);
            }
            return typeid(_cause) == typeid(CancellationException);
        }
        return false;
    }

    bool IsDone() {
        return _isCompleted;
    }

    T Get() {
        return Get(-1.msecs);
    }

    T Get(Duration timeout) {
        // waitting for the completion
        if(!_isCompleted) {
            _waiterLocker.lock();
            scope(exit) {
                _waiterLocker.unlock();
            }

            if(timeout.isNegative()) {
                version (GEAR_DEBUG) Info("Waiting for a promise...");
                _waiterCondition.wait();
            } else {
                version (GEAR_DEBUG) {
                    Infof("Waiting for a promise in %s...", timeout);
                }
                bool r = _waiterCondition.wait(timeout);
                if(!r) {
                    debug Warningf("Timeout for a promise in %s...", timeout);
                    if (cas(&_isCompleting, false, true)) {
                        _isCompleted = true;
                        _cause = new TimeoutException("Timeout in " ~ timeout.toString());
                    }
                }
            }
            
            if(_cause is null) {
                version (GEAR_DEBUG) Infof("Got a succeeded promise.");
            } else {
                version (GEAR_DEBUG) Warningf("Got a failed promise: %s", typeid(_cause));
            }
        } 

        // succeeded
        if (_cause is null) {
            static if(is(T == void)) {
                return;
            } else {
                return _result;
            }
        }

        CancellationException c = cast(CancellationException) _cause;
        if (c !is null) {
            version(GEAR_DEBUG) Info("A promise cancelled.");
            throw c;
        }
        
        debug Warning("Get a exception in a promise: ", _cause.msg);
        version (GEAR_DEBUG) Warning(_cause);
        throw new ExecutionException(_cause);
    }    

    override string toString() {
        static if(is(T == void)) {
            return format("FutureCallback@%x{%b, %b, void}", toHash(), _isCompleted, _cause is null);
        } else {
            return format("FutureCallback@%x{%b, %b, %s}", toHash(), _isCompleted, _cause is null, _result);
        }
    }
}
