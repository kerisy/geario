module geario.util.pool.PooledObject;

import core.atomic;
import std.datetime;

import geario.util.pool.PooledObjectState;

/**
 * Defines the wrapper that is used to track the additional information, such as
 * state, for the pooled objects.
 * <p>
 * Implementations of this class are required to be thread-safe.
 *
 * @param <T> the type of object in the pool
 *
 */
class PooledObject(T) {
    private size_t _id;
    private T _obj;
    private PooledObjectState _state;
    private SysTime _createTime;
    private SysTime _lastBorrowTime;
    private SysTime _lastUseTime;
    private SysTime _lastReturnTime;
    private shared long _borrowedCount = 0;
    private static shared size_t _counter;

    this(T obj) {
        _obj = obj;
        _state = PooledObjectState.IDLE;
        _createTime = Clock.currTime;
        _id = atomicOp!("+=")(_counter, 1);
    }

    size_t Id() {
        return _id;
    }

    /**
     * Obtains the underlying object that is wrapped by this instance of
     * {@link PooledObject}.
     *
     * @return The wrapped object
     */
    T GetObject() {
        return _obj;
    }  

    SysTime CreateTime() {
        return _createTime;
    }    

    SysTime LastBorrowTime() {
        return _lastBorrowTime;
    }

    SysTime LastReturnTime() {
        return _lastReturnTime;
    }

    /**
     * Get the number of times this object has been borrowed.
     * @return The number of times this object has been borrowed.
     */
    long BorrowedCount() {
        return _borrowedCount;
    }

    /**
     * Returns the state of this object.
     * @return state
     */
    PooledObjectState State() {
        return _state;
    }

    /**
     * Allocates the object.
     *
     * @return {@code true} if the original state was {@link PooledObjectState#IDLE IDLE}
     */
    bool Allocate() {
        if (_state == PooledObjectState.IDLE) {
            _state = PooledObjectState.ALLOCATED;
            _lastBorrowTime = Clock.currTime;
            _lastUseTime = _lastBorrowTime;
            atomicOp!("+=")(_borrowedCount, 1);
            // if (logAbandoned) {
            //     borrowedBy.fillInStackTrace();
            // }
            return true;
        } 
        
        // else if (state == PooledObjectState.EVICTION) {
        //     // TODO Allocate anyway and ignore eviction test
        //     state = PooledObjectState.EVICTION_RETURN_TO_HEAD;
        //     return false;
        // }
        // TODO if validating and testOnBorrow == true then pre-allocate for
        // performance
        return false;        
    }

    /**
     * Deallocates the object and sets it {@link PooledObjectState#IDLE IDLE}
     * if it is currently {@link PooledObjectState#ALLOCATED ALLOCATED}.
     *
     * @return {@code true} if the state was {@link PooledObjectState#ALLOCATED ALLOCATED}
     */
    bool Deallocate() {

        if (_state == PooledObjectState.ALLOCATED || _state == PooledObjectState.RETURNING) {
            _state = PooledObjectState.IDLE;
            _lastReturnTime = Clock.currTime;
            return true;
        }

        return false;
    }

    /**
     * Sets the state to {@link PooledObjectState#INVALID INVALID}
     */
    void Invalidate() { // synchronized
        _state = PooledObjectState.INVALID;
    }


    /**
     * Marks the pooled object as abandoned.
     */
    void Abandoned() { // synchronized
        _state = PooledObjectState.ABANDONED;
    }

    /**
     * Marks the object as returning to the pool.
     */
    void Returning() { // synchronized
        _state = PooledObjectState.RETURNING;
    }

    bool IsIdle() {
        return _state == PooledObjectState.IDLE;
    }

    bool IsInUse() {
        return _state == PooledObjectState.ALLOCATED;
    }

    bool IsInvalid() {
        return _state == PooledObjectState.INVALID;
    }
}
