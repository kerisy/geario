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

module geario.event.EventLoop;

import geario.event.selector;
import geario.net.channel.Types;
import geario.logging;
import geario.util.worker;

import core.thread;
import std.parallelism;
import std.random;

/**
 * 
 */
final class EventLoop : AbstractSelector
{
    this()
    {
        int id = uniform(0, 1024);
        super(id, 1);
    }

    this(Worker worker)
    {
        int id = uniform(0, 1024);
        super(id, 1, worker);
    }

    this(size_t id, size_t divider, Worker worker = null)
    {
        super(id, divider, worker);
    }

    void StartLoop()
    {
        Run(timeout);
    }
    
    override void Stop() {
        if(IsStopping()) {
            version (GEAR_IO_DEBUG) 
            log.warn("The event loop %d is stopping.", GetId());
            return;
        }
        
        version (GEAR_IO_DEBUG) 
        log.trace("Stopping event loop %d...", GetId());
        if(IsSelfThread()) {
            version (GEAR_IO_DEBUG) log.info("Try to stop the event loop %d in another thread", GetId());
            auto stopTask = task(&Stop);
            std.parallelism.taskPool.put(stopTask);
        } else {
            super.Stop();
        }
    }
}
