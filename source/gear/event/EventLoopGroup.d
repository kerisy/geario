/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.event.EventLoopGroup;

import gear.event.EventLoop;
import gear.logging.ConsoleLogger;
import gear.system.Memory;
import gear.util.Lifecycle;
import gear.util.worker;

import core.atomic;

/**
 * 
 */
class EventLoopGroup : Lifecycle {
    private TaskQueue _pool;
    private Worker _worker;

    this(size_t ioThreadSize = (totalCPUs - 1), size_t workerThreadSize = 0) {
        size_t _size = ioThreadSize > 0 ? ioThreadSize : 1;

        version(GEAR_DEBUG) Infof("ioThreadSize: %d, workerThreadSize: %d", ioThreadSize, workerThreadSize);

        _eventLoops = new EventLoop[_size];

        if(workerThreadSize > 0) {
            _pool = new MemoryTaskQueue();
            _worker = new Worker(_pool, workerThreadSize);
            _worker.Run();
        } 

        foreach (i; 0 .. _size) {
            _eventLoops[i] = new EventLoop(i, _size, _worker);
        }
    }

    void Start() {
        Start(-1);
    }

    Worker worker() {
        return _worker;
    }

    /**
        timeout: in millisecond
    */
    void Start(long timeout) {
        if (cas(&_isRunning, false, true)) {
            foreach (EventLoop pool; _eventLoops) {
                pool.RunAsync(timeout);
            }
        }
    }

    void Stop() {
        if (!cas(&_isRunning, true, false))
            return;

        if(_worker !is null) {
            _worker.Stop();
        }

        version (GEAR_IO_DEBUG)
            Trace("stopping EventLoopGroup...");
        foreach (EventLoop pool; _eventLoops) {
            pool.Stop();
        }

        version (GEAR_IO_DEBUG)
            Trace("EventLoopGroup stopped.");
    }

    bool IsRunning() {
        return _isRunning;
    }

    bool IsReady() {
        
        foreach (EventLoop pool; _eventLoops) {
            if(!pool.IsReady()) return false;
        }

        return true;
    }

    @property size_t size() {
        return _eventLoops.length;
    }

    EventLoop nextLoop(size_t factor) {
       return _eventLoops[factor % _eventLoops.length];
    }

    EventLoop OpIndex(size_t index) {
        auto i = index % _eventLoops.length;
        return _eventLoops[i];
    }

    int opApply(scope int delegate(EventLoop) dg) {
        int ret = 0;
        foreach (pool; _eventLoops) {
            ret = dg(pool);
            if (ret)
                break;
        }
        return ret;
    }

private:
    shared int _loopIndex;
    shared bool _isRunning;
    EventLoop[] _eventLoops;
}
