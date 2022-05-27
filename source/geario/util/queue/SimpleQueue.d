module geario.util.queue.SimpleQueue;

import geario.logging;
import geario.util.queue.Queue;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;
import core.time;
import core.thread;

import std.container.dlist;
// import ikod.containers.unrolledlist: UnrolledList;

/**
 * It's a thread-safe queue
 */
class SimpleQueue(T) : Queue!(T) {
    private DList!T _list;
    // private UnrolledList!T _list;
    private Mutex _headLock;
    private Duration _timeout;
    private bool _isWaiting = false;

    shared int _incomings = 0;
    shared int _outgoings = 0;

    /** Wait queue for waiting takes */
    private Condition _notEmpty;

    this(Duration timeout = 10.seconds) {
        _timeout = timeout;
        _headLock = new Mutex();
        _notEmpty = new Condition(_headLock);
    }

    override bool IsEmpty() {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        return _list.empty();
    }

    override void Clear() {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();
        _list.clear();
    }

    override T Pop() {
        _headLock.lock();
        scope (exit) {
            _headLock.unlock();
        }

        if(IsEmpty()) {
            _isWaiting = true;
            bool v = _notEmpty.wait(_timeout);
            _isWaiting = false;
            if(!v) {
                version (GEAR_IO_DEBUG) {
                    log.trace("Timeout in %s.", _timeout);
                }
                return T.init;
            }
        }

        T item = _list.front();
        _list.removeFront();

        return item;
    }

    override void Push(T item) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        _list.insert(item);

        if(_isWaiting) {
            _notEmpty.notify();
        }
    }

    bool TryDequeue(out T item) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();
        
        if(_list.empty()) {
            return false;
        }

        item = _list.front();
        _list.removeFront();

        return true;
    }
}
