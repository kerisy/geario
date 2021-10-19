module gear.event.EventLoopPool;

import gear.logging.ConsoleLogger;
import gear.event.EventLoop;
import gear.util.pool;

import std.concurrency : initOnce;

alias EventLoopPool = ObjectPool!EventLoop;

private __gshared EventLoopPool _pool;

EventLoopPool eventLoopPool() {
    return initOnce!_pool(buildEventLoopPool());
}    

void buildEventLoopPool(PoolOptions options) {
    initOnce!_pool(new EventLoopPool(new EventLoopObjectFactory(), options));
}

private EventLoopPool buildEventLoopPool() {
    PoolOptions options = new PoolOptions();
    options.size = 64;
    EventLoopPool objPool = new EventLoopPool(new EventLoopObjectFactory(), options);
    return objPool;
}

void shutdownEventLoopPool() {
    if(_pool !is null) {
        _pool.Close();
    }
}

/**
 * 
 */
class EventLoopObjectFactory : ObjectFactory!(EventLoop) {

    override EventLoop MakeObject() {
        EventLoop r = new EventLoop();
        r.RunAsync();

        while(!r.IsReady()) {
            version(GEAR_IO_DEBUG) Warning("Waiting for the eventloop got ready...");
        }

        return r;
    }    

    override void DestroyObject(EventLoop p) {
        p.Stop();
    }

    override bool IsValid(EventLoop p) {
        return p.IsRuning();
    }
}