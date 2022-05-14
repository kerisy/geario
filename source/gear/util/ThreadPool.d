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

module gear.util.ThreadPool;

import core.thread;

import gear.logging;

import core.sync.mutex;
import core.sync.condition;

import std.container.dlist;

alias void delegate() ThreadTask;

class ThreadPool
{
public:
    this(size_t capacity = 8)
    {
        _capacity  = capacity;
        _mutex     = new Mutex;
        _condition = new Condition( _mutex );
        _group     = new ThreadGroup;

        Init();
    }

    ~this()
    {
        if (!_stopped)
            Stop();
    }

    void Stop()
    {
        _stopped = true;
        _condition.notifyAll();
        _group.joinAll();
        _threads = null;
    }

    void Emplace(ThreadTask task)
    {
        synchronized( _mutex )
        {
            _tasks.insertBack(task);
            _condition.notify();

            Thread.yield();
        }
    }

private:
    void Init()
    {
        for ( size_t i = 0; i < _capacity; i++ )
        {
            _threads ~= _group.create(&Work);
        }
    }

    void Work()
    {
        while (!_stopped)
        {
            ThreadTask task;
            synchronized( _mutex )
            {
                if (_tasks.empty())
                {
                    _condition.wait();
                }

                if ( !_tasks.empty() )
                {
                    task = _tasks.front();
                    _tasks.removeFront();
                }
            }

            if(task !is null)
            {
                task();
            }
        }
    }

    DList!ThreadTask _tasks;
    size_t           _capacity;
    bool             _stopped;
    Mutex            _mutex;
    Condition        _condition;
    ThreadGroup      _group;
    Thread[]         _threads;
}
