module gear.util.ResoureManager;

import gear.logging.ConsoleLogger;
import gear.util.Closeable;

import gear.util.worker.WorkerThread;

import core.memory;
import core.thread;

private Closeable[] _closeableObjects;

void RegisterResoure(Closeable res) {
    assert(res !is null);
    foreach (Closeable obj; _closeableObjects) {
        if(obj is res) {
            version (GEAR_IO_DEBUG) {
                Tracef("%s@%s has been registered... %d", typeid(cast(Object)res), cast(void*)res);
            }
            return;
        }
    }
    _closeableObjects ~= res;
}

void CollectResoure() nothrow {
    version (GEAR_IO_DEBUG) {
        Tracef("Collecting (remains: %d)...", _closeableObjects.length);
    }

    Closeable[] objects = _closeableObjects;
    _closeableObjects = null;

    foreach (obj; objects) {
        try {
            obj.Close();
        } catch (Throwable t) {
            Warning(t);
        }
    }

    // GC.collect();
    // GC.minimize();
}
