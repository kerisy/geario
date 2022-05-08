/*
 * Hunt - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module gear.util.Common;

import gear.util.Runnable;

import gear.logging.ConsoleLogger;


/**
 * Implementing this interface allows an object to be the target of
 * the "for-each loop" statement. 
 * @param (T) the type of elements returned by the iterator
 */
interface Iterable(T) {
   int opApply(scope int delegate(ref T) dg);
}

interface Iterable(K, V) {
   int opApply(scope int delegate(ref K, ref V) dg);
}


/**
 * A class implements the <code>Cloneable</code> interface to
 * indicate to the {@link java.lang.Object#clone()} method that it
 * is legal for that method to make a
 * field-for-field copy of instances of that class.
 * <p>
 * Invoking Object's clone method on an instance that does not implement the
 * <code>Cloneable</code> interface results in the exception
 * <code>CloneNotSupportedException</code> being thrown.
 * <p>
 * By convention, classes that implement this interface should override
 * <tt>Object.clone</tt> (which is protected) with a method.
 * See {@link java.lang.Object#clone()} for details on overriding this
 * method.
 * <p>
 * Note that this interface does <i>not</i> contain the <tt>clone</tt> method.
 * Therefore, it is not possible to clone an object merely by virtue of the
 * fact that it implements this interface.  Even if the clone method is invoked
 * reflectively, there is no guarantee that it will succeed.
 */
interface Cloneable {
    //Object clone();
}


// /**
//  * A {@code Flushable} is a destination of data that can be flushed.  The
//  * flush method is invoked to write any buffered output to the underlying
//  * stream.
//  */
// interface Flushable {

//     /**
//      * Flushes this stream by writing any buffered output to the underlying
//      * stream.
//      *
//      * @throws IOException If an I/O error occurs
//      */
//     void flush();
// }

// /**
// */
// interface Serializable {

//     ubyte[] serialize();

//     // void deserialize(ubyte[] data);
// }


interface Comparable(T) {
    // TODO: Tasks pending completion -@zxp at 12/30/2018, 10:17:44 AM
    // 
    // int opCmp(T o) nothrow;
    int opCmp(T o);

    // deprecated("Use opCmp instead.")
    // alias compareTo = opCmp;
}


/**
 * A task that returns a result and may throw an exception.
 * Implementors define a single method with no arguments called
 * {@code call}.
 *
 * <p>The {@code Callable} interface is similar to {@link
 * java.lang.Runnable}, in that both are designed for classes whose
 * instances are potentially executed by another thread.  A
 * {@code Runnable}, however, does not return a result and cannot
 * throw a checked exception.
 *
 * <p>The {@link Executors} class contains utility methods to
 * convert from other common forms to {@code Callable} classes.
 *
 * @see Executor
 * @author Doug Lea
 * @param <V> the result type of method {@code call}
 */
interface Callable(V) {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call();
}


/**
 * An object that executes submitted {@link Runnable} tasks. This
 * interface provides a way of decoupling task submission from the
 * mechanics of how each task will be run, including details of thread
 * use, scheduling, etc.  An {@code Executor} is normally used
 * instead of explicitly creating threads. For example, rather than
 * invoking {@code new Thread(new RunnableTask()).start()} for each
 * of a set of tasks, you might use:
 *
 * <pre> {@code
 * Executor executor = anExecutor();
 * executor.Execute(new RunnableTask1());
 * executor.Execute(new RunnableTask2());
 * ...}</pre>
 *
 * However, the {@code Executor} interface does not strictly require
 * that execution be asynchronous. In the simplest case, an executor
 * can run the submitted task immediately in the caller's thread:
 *
 * <pre> {@code
 * class DirectExecutor implements Executor {
 *   public void Execute(Runnable r) {
 *     r.run();
 *   }
 * }}</pre>
 *
 * More typically, tasks are executed in some thread other than the
 * caller's thread.  The executor below spawns a new thread for each
 * task.
 *
 * <pre> {@code
 * class ThreadPerTaskExecutor implements Executor {
 *   public void Execute(Runnable r) {
 *     new Thread(r).start();
 *   }
 * }}</pre>
 *
 * Many {@code Executor} implementations impose some sort of
 * limitation on how and when tasks are scheduled.  The executor below
 * serializes the submission of tasks to a second executor,
 * illustrating a composite executor.
 *
 * <pre> {@code
 * class SerialExecutor implements Executor {
 *   final Queue!(Runnable) tasks = new ArrayDeque<>();
 *   final Executor executor;
 *   Runnable active;
 *
 *   SerialExecutor(Executor executor) {
 *     this.executor = executor;
 *   }
 *
 *   public synchronized void Execute(Runnable r) {
 *     tasks.add(() -> {
 *       try {
 *         r.run();
 *       } finally {
 *         scheduleNext();
 *       }
 *     });
 *     if (active is null) {
 *       scheduleNext();
 *     }
 *   }
 *
 *   protected synchronized void scheduleNext() {
 *     if ((active = tasks.poll()) !is null) {
 *       executor.Execute(active);
 *     }
 *   }
 * }}</pre>
 *
 * The {@code Executor} implementations provided in this package
 * implement {@link ExecutorService}, which is a more extensive
 * interface.  The {@link ThreadPoolExecutor} class provides an
 * extensible thread pool implementation. The {@link Executors} class
 * provides convenient factory methods for these Executors.
 *
 * <p>Memory consistency effects: Actions in a thread prior to
 * submitting a {@code Runnable} object to an {@code Executor}
 * <a href="package-summary.html#MemoryVisibility"><i>happen-before</i></a>
 * its execution begins, perhaps in another thread.
 *
 * @author Doug Lea
 */
interface Executor {

    /**
     * Executes the given command at some time in the future.  The command
     * may execute in a new thread, in a pooled thread, or in the calling
     * thread, at the discretion of the {@code Executor} implementation.
     *
     * @param command the runnable task
     * @throws RejectedExecutionException if this task cannot be
     * accepted for execution
     * @throws NullPointerException if command is null
     */
    void Execute(Runnable command);
}



// /**
//  * <p>
//  * A callback abstraction that handles completed/failed events of asynchronous
//  * operations.
//  * </p>
//  * <p>
//  * <p>
//  * Semantically this is equivalent to an optimise Promise&lt;Void&gt;, but
//  * callback is a more meaningful name than EmptyPromise
//  * </p>
//  */
// interface Callback {
//     /**
//      * Instance of Adapter that can be used when the callback methods need an
//      * empty implementation without incurring in the cost of allocating a new
//      * Adapter object.
//      */
//     __gshared Callback NOOP;

//     shared static this() {
//         NOOP = new NoopCallback();
//     }

//     /**
//      * <p>
//      * Callback invoked when the operation completes.
//      * </p>
//      *
//      * @see #Failed(Throwable)
//      */
//     void Succeeded();

//     /**
//      * <p>
//      * Callback invoked when the operation fails.
//      * </p>
//      *
//      * @param x the reason for the operation failure
//      */
//     void Failed(Exception x);

//     /**
//      * @return True if the callback is known to never block the caller
//      */
//     bool IsNonBlocking();
// }

// /**
//  * 
//  */
// class NestedCallback : Callback {
//     private Callback callback;

//     this(Callback callback) {
//         this.callback = callback;
//     }

//     this(NestedCallback nested) {
//         this.callback = nested.callback;
//     }

//     Callback GetCallback() {
//         return callback;
//     }

//     void Succeeded() {
//         if(callback is null) {
//             version(GEAR_DEBUG) warning("callback is null");
//         } else {
//             callback.Succeeded();
//         }
//     }

//     void Failed(Exception x) {
//         if(callback is null) {
//             version(GEAR_DEBUG) warning("callback is null");
//         } else {
//             callback.Failed(x);
//         }
//     }

//     bool IsNonBlocking() {
//         if(callback is null) {
//             version(GEAR_DEBUG) warning("callback is null");
//             return false;
//         } else {
//             return callback.IsNonBlocking();
//         }
//     }
// }

// /**
//  * <p>
//  * A callback abstraction that handles completed/failed events of asynchronous
//  * operations.
//  * </p>
//  * <p>
//  * <p>
//  * Semantically this is equivalent to an optimise Promise&lt;Void&gt;, but
//  * callback is a more meaningful name than EmptyPromise
//  * </p>
//  */
// class NoopCallback : Callback {
//     /**
//      * <p>
//      * Callback invoked when the operation completes.
//      * </p>
//      *
//      * @see #Failed(Throwable)
//      */
//     void Succeeded() {
//     }

//     /**
//      * <p>
//      * Callback invoked when the operation fails.
//      * </p>
//      *
//      * @param x the reason for the operation failure
//      */
//     void Failed(Exception x) {
//     }

//     /**
//      * @return True if the callback is known to never block the caller
//      */
//     bool IsNonBlocking() {
//         return true;
//     }
// }
