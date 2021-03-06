/*
 * Hunt - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (T) 2018-2019 HuntLabs
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module geario.concurrency.Promise;

import geario.Exceptions;

/**
 * <p>A callback abstraction that handles completed/failed events of asynchronous operations.</p>
 *
 * @param <T> the type of the context object
 *
 * See_Also:
 *  https://www.eclipse.org/jetty/javadoc/9.4.7.v20170914/org/eclipse/jetty/util/Promise.html
 */
interface Promise(T) {

    /**
     * <p>Callback invoked when the operation completes.</p>
     *
     * @param result the context
     * @see #Failed(Throwable)
     */
    static if (is(T == void)) {
        void Succeeded();
    } else {
        void Succeeded(T result);
    }
    /**
     * <p>Callback invoked when the operation fails.</p>
     *
     * @param x the reason for the operation failure
     */
    void Failed(Exception x);
}

/**
 * <p>Empty implementation of {@link Promise}.</p>
 *
 * @param (T) the type of the result
 */
class DefaultPromise(T) : Promise!T {

    static if (is(T == void)) {
        void Succeeded() {

        }
    } else {
        void Succeeded(T result) {

        }
    }

    void Failed(Exception x) {
    }
}
