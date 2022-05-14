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

module gear.util.pool.ObjectFactory;

import gear.logging.ConsoleLogger;

abstract class ObjectFactory(T) {

    T MakeObject();

    void DestroyObject(T p) {
        version(GEAR_DEBUG) Trace("Do noting");
    }

    bool IsValid(T p) {
        return true;
    }
}


class DefaultObjectFactory(T) : ObjectFactory!(T) {

    override T MakeObject() {
        return new T();
    }

}
