module geario.util.ResoureManager;

import geario.logging;
import geario.util.Closeable;

import geario.util.worker.WorkerThread;

import core.memory;
import core.thread;

private Closeable[] _closeableObjects;

void RegisterResoure(Closeable res) {
    assert(res !is null);
    foreach (Closeable obj; _closeableObjects) {
        if(obj is res) {
            version (GEAR_IO_DEBUG) {
                log.trace("%s@%s has been registered... %d", typeid(cast(Object)res), cast(void*)res);
            }
            return;
        }
    }
    _closeableObjects ~= res;
}

void CollectResoure() {
    version (GEAR_IO_DEBUG) {
        log.trace("Collecting (remains: %d)...", _closeableObjects.length);
    }

    Closeable[] objects = _closeableObjects;
    _closeableObjects = null;

    foreach (obj; objects) {
        try {
            obj.Close();
        } catch (Throwable t) {
            log.warning(t);
        }
    }

    // GC.collect();
    // GC.minimize();
}
