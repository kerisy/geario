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

module gear.util.Lifecycle;

import core.atomic;


import gear.logging.ConsoleLogger;

/**
 * A common interface defining methods for start/stop lifecycle control.
 * The typical use case for this is to control asynchronous processing.
 */
interface Lifecycle {
    /**
     * Start this component.
     * <p>Should not throw an exception if the component is already running.
     * <p>In the case of a container, this will propagate the start signal to all
     * components that apply.
     */    
    void Start();

    /**
     * Stop this component, typically in a synchronous fashion, such that the component is
     * fully stopped upon return of this method. 
     */
    void Stop();


    /**
     * Check whether this component is currently running.
     * @return whether the component is currently running
     */
    bool IsRunning();
}


abstract class AbstractLifecycle : Lifecycle {

    protected shared bool _isRunning;

    this() {
       
    }

    bool IsRunning() {
        return _isRunning;
    }

    bool IsStopped() {
        return !_isRunning;
    }

    void Start() {
        if (cas(&_isRunning, false, true)) {
            Initialize();
        } else {
            version(GEAR_DEBUG) Warning("Starting repeatedly!");
        }
    }

    void Stop() {
        if (cas(&_isRunning, true, false)) {
            Destroy();
        } else {
            version(GEAR_DEBUG) Warning("Stopping repeatedly!");
        }
    }

    abstract protected void Initialize();

    abstract protected void Destroy();
}
