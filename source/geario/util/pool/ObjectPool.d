module geario.util.pool.ObjectPool;

import geario.concurrency.Future;
import geario.concurrency.Promise;
import geario.concurrency.FuturePromise;
import geario.logging;

import core.sync.mutex;

import std.container.dlist;
import core.time;
import std.format;
import std.range : walkLength;

import geario.util.pool.ObjectFactory;
import geario.util.pool.PooledObject;

/**
 * 
 */
enum CreationMode {
    Lazy,
    Eager
}

/**
 * 
 */
class PoolOptions {
    size_t size = 5;
    CreationMode creationMode = CreationMode.Lazy;
}


/**
 * 
 */
class ObjectPool(T) {
    private ObjectFactory!(T) _factory;
    private PooledObject!(T)[] _pooledObjects;
    private Mutex _locker;
    private DList!(FuturePromise!T) _waiters;
    private PoolOptions _poolOptions;

    this(PoolOptions options) {
        this(new DefaultObjectFactory!(T)(), options);
    }

    this(ObjectFactory!(T) factory, PoolOptions options) {
        _factory = factory;
        _poolOptions = options;
        _pooledObjects = new PooledObject!(T)[options.size];
        _locker = new Mutex();
    }

    size_t size() {
        return _poolOptions.size;
    }

    /**
     * Obtains an instance from this pool.
     * <p>
     * By contract, clients <strong>must</strong> return the borrowed instance
     * using {@link #ReturnObject}, {@link #invalidateObject}, or a related
     * method as defined in an implementation or sub-interface.
     * </p>
     * <p>
     * The behaviour of this method when the pool has been exhausted
     * is not strictly specified (although it may be specified by
     * implementations).
     * </p>
     *
     * @return an instance from this pool.
     */
    T Borrow(Duration timeout = 10.seconds, bool isQuiet = true) {
        T r;
        if(timeout == Duration.zero) {
            _locker.lock();
            scope(exit) {
                _locker.unlock();
            }

            r = DoBorrow();
            if(r is null && !isQuiet) {
                throw new Exception("No idle object avaliable.");
            }
        } else {
            Future!T future = BorrowAsync();
            if(timeout.isNegative()) {
                r = future.Get();
            } else {
                r = future.Get(timeout);
            }
        }
        return r;
    }    


    /**
     * 
     */
    Future!T BorrowAsync() {
        _locker.lock();
        scope(exit) {
            _locker.unlock();
        }
        
        FuturePromise!T promise = new FuturePromise!T();

        if(_waiters.empty()) {
            T r = DoBorrow();
            if(r is null) {
                _waiters.stableInsert(promise);
                version(GEAR_DEBUG) {
                    log.warn("New waiter...%d", GetNumWaiters());
                }
            } else {
                promise.Succeeded(r);
            }
        } else {
            _waiters.stableInsert(promise);
            version(GEAR_DEBUG) {
                log.warn("New waiter...%d", GetNumWaiters());
            }
        }

        return promise;
    }

    /**
     * 
     */
    private T DoBorrow() {
        PooledObject!(T) pooledObj;

        for(size_t index; index<_pooledObjects.length; index++) {
            pooledObj = _pooledObjects[index];

            if(pooledObj is null) {
                T underlyingObj = _factory.MakeObject();
                pooledObj = new PooledObject!(T)(underlyingObj);
                _pooledObjects[index] = pooledObj;
                break;
            } else if(pooledObj.IsIdle()) {
                T underlyingObj = pooledObj.GetObject();
                bool isValid = _factory.IsValid(underlyingObj);
                if(!isValid) {
                    pooledObj.Invalidate();
                    version(GEAR_DEBUG) {
                        log.warn("An invalid object (id=%d) detected at slot %d.", pooledObj.Id(), index);
                    }
                    _factory.DestroyObject(underlyingObj);
                    underlyingObj = _factory.MakeObject();
                    pooledObj = new PooledObject!(T)(underlyingObj);
                    _pooledObjects[index] = pooledObj;
                }
                break;
            } else if(pooledObj.IsInvalid()) {
                T underlyingObj = pooledObj.GetObject();
                version(GEAR_DEBUG) {
                    log.warn("An invalid object (id=%d) detected at slot %d.", pooledObj.Id(), index);
                }
                _factory.DestroyObject(underlyingObj);
                underlyingObj = _factory.MakeObject();
                pooledObj = new PooledObject!(T)(underlyingObj);
                _pooledObjects[index] = pooledObj;
                break;
            }

            pooledObj = null;
        }
        
        if(pooledObj is null) {
            version(GEAR_DEBUG) {
                log.warn("No idle object avaliable.");
            }
            return null;
        }
        
        pooledObj.Allocate();

        version(GEAR_DEBUG) {
            log.info("borrowed: id=%d, createTime=%s; pool status = { %s }", 
                pooledObj.Id(), pooledObj.CreateTime(), toString()); 
        }
        return pooledObj.GetObject();        
    }

    /**
     * Returns an instance to the pool. By contract, <code>obj</code>
     * <strong>must</strong> have been obtained using {@link #borrowObject()} or
     * a related method as defined in an implementation or sub-interface.
     *
     * @param obj a {@link #borrowObject borrowed} instance to be returned.
     */
    void ReturnObject(T obj) {
        if(obj is null) {
            version(GEAR_DEBUG) log.warn("Do nothing for a null object");
            return;
        }

        scope(exit) {
            _locker.lock();
            scope(exit) {
                _locker.unlock();
            }
            HandleWaiters();
        }

        DoReturning(obj);
    } 

    private bool DoReturning(T obj) {
        bool result = false;

        PooledObject!(T) pooledObj;
        for(size_t index; index<_pooledObjects.length; index++) {
            pooledObj = _pooledObjects[index];
            if(pooledObj is null) {
                continue;
            }
            
            T underlyingObj = pooledObj.GetObject();
            if(underlyingObj is obj) {
                version(GEAR_DEBUG_MORE) {
                    log.trace("returning: id=%d, state=%s, count=%s, createTime=%s", 
                        pooledObj.Id(), pooledObj.State(), pooledObj.BorrowedCount(), pooledObj.CreateTime()); 
                }
                    
                // pooledObj.Returning();
                result = pooledObj.Deallocate();
                version(GEAR_DEBUG) {
                    if(result) {
                        log.info("Returned: id=%d", pooledObj.Id());
                    } else {
                        log.warn("Return failed: id=%d", pooledObj.Id());
                    }
                }
                break;
            }
        }

        version(GEAR_DEBUG) {
            Info(toString());
        }
        return result;
    }

    private void HandleWaiters() {
        if(_waiters.empty())
            return;
        
        FuturePromise!T waiter = _waiters.front();

        // clear up all the finished waiter
        while(waiter.IsDone()) {
            _waiters.removeFront();
            if(_waiters.empty()) {
                return;
            }

            waiter = _waiters.front();
        }

        // 
        T r = DoBorrow();
        if(r is null) {
            log.warn("No idle object avaliable for waiter");
        } else {
            _waiters.removeFront();
            try {
                waiter.Succeeded(r);
            } catch(Exception ex) {
                log.warn(ex);
            }
        }
    }

    /**
     * Returns the number of instances currently idle in this pool. This may be
     * considered an approximation of the number of objects that can be
     * {@link #borrowObject borrowed} without creating any new instances.
     * Returns a negative value if this information is not available.
     * @return the number of instances currently idle in this pool.
     */
    size_t GetNumIdle() {
        size_t count = 0;

        foreach(PooledObject!(T) obj; _pooledObjects) {
            if(obj is null || obj.IsIdle()) {
                count++;
            } 
        }

        return count;
    }

    /**
     * Returns the number of instances currently borrowed from this pool. Returns
     * a negative value if this information is not available.
     * @return the number of instances currently borrowed from this pool.
     */
    size_t GetNumActive() {
        size_t count = 0;

        foreach(PooledObject!(T) obj; _pooledObjects) {
            if(obj !is null && obj.IsInUse()) {
                count++;
            } 
        }

        return count;        
    }

    /**
     * Returns an estimate of the number of threads currently blocked waiting for
     * an object from the pool. This is intended for monitoring only, not for
     * synchronization control.
     *
     * @return The estimate of the number of threads currently blocked waiting
     *         for an object from the pool
     */
    size_t GetNumWaiters() {
        return walkLength(_waiters[]);
    }

    /**
     * Clears any objects sitting idle in the pool, releasing any associated
     * resources (optional operation). Idle objects cleared must be
     * {@link PooledObjectFactory#DestroyObject(PooledObject)}.
     *
     * @throws Exception if the pool cannot be cleared
     */
    void Clear() {
        version(GEAR_DEBUG) {
            Info("Pool is clearing...");
        }

        _locker.lock();
        scope(exit) {
            _locker.unlock();
        }

        for(size_t index; index<_pooledObjects.length; index++) {
            PooledObject!(T) obj = _pooledObjects[index];

            if(obj !is null) {
                version(GEAR_DEBUG) {
                    log.trace("clearing object: id=%d, slot=%d", obj.Id(), index);
                }

                _pooledObjects[index] = null;
                obj.Abandoned();
                _factory.DestroyObject(obj.GetObject());
            }
        }
    }

    /**
     * Closes this pool, and free any resources associated with it.
     * <p>
     * Calling {@link #borrowObject} after invoking this
     * method on a pool will cause them to throw an {@link IllegalStateException}.
     * </p>
     * <p>
     * Implementations should silently fail if not all resources can be freed.
     * </p>
     */
    void Close() {
        version(GEAR_DEBUG) {
            Info("Pool is closing...");
        }

        _locker.lock();
        scope(exit) {
            _locker.unlock();
        }

        for(size_t index; index<_pooledObjects.length; index++) {
            PooledObject!(T) obj = _pooledObjects[index];

            if(obj !is null) {
                version(GEAR_DEBUG) {
                    log.trace("destroying object: id=%d, slot=%d", obj.Id(), index);
                }

                _pooledObjects[index] = null;
                obj.Abandoned();
                _factory.DestroyObject(obj.GetObject());
            }
        }

    }

    override string toString() {
        string str = format("Total: %d, Active: %d, Idle: %d, Waiters: %d", 
                size(), GetNumActive(),  GetNumIdle(), GetNumWaiters());
        return str;
    }
}