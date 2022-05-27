module geario.util.worker.Worker;

import geario.util.worker.Task;
// import geario.util.worker.TaskQueue;
import geario.util.worker.WorkerThread;
import geario.logging;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;
import core.thread;

import std.conv; 
import std.concurrency;



/**
 * 
 */
class Worker {

    private size_t _size;
    private WorkerThread[] _workerThreads;
    private Task[size_t] _tasks;
    private Mutex _taskLocker;


    private TaskQueue _taskQueue;
    private shared bool _isRunning = false;

    this(TaskQueue taskQueue, size_t size = 8) {
        _taskQueue = taskQueue;
        _size = size;

        version(GEAR_DEBUG) {
            log.info("Worker size: %d", size);
        }

        Initialize();
    }

    private void Initialize() {
        _taskLocker = new Mutex();
        _workerThreads = new WorkerThread[_size];
        
        foreach(size_t index; 0 .. _size) {
            WorkerThread thread = new WorkerThread(index);
            thread.start();

            _workerThreads[index] = thread;
        }
    }

    void Inspect() {

        foreach(WorkerThread th; _workerThreads) {
            
            Task task = th.task();

            if(th.State() == WorkerThreadState.Busy) {
                if(task is null) {
                    log.warning("A dead worker thread detected: %s, %s", th.name, th.State());
                } else {
                    log.trace("Thread: %s,  state: %s, LifeTime: %s", th.name, th.State(), task.LifeTime());
                }
            } else {
                if(task is null) {
                    log.trace("Thread: %s,  state: %s", th.name, th.State());
                } else {
                    log.trace("Thread: %s,  state: %s", th.name, th.State(), task.ExecutionTime);
                }
            }
        }
    }

    void put(Task task) {
        _taskQueue.Push(task);

        _taskLocker.lock();
        scope(exit) {
            _taskLocker.unlock();
        }

        _tasks[task.id] = task;
    }

    Task get(size_t id) {
        _taskLocker.lock();
        scope(exit) {
            _taskLocker.unlock();
        } 

        auto itemPtr = id in _tasks;
        if(itemPtr is null) {
            throw new Exception("Task does NOT exist: " ~ id.to!string);
        }

        return *itemPtr;
    }

    void Remove(size_t id) {
        _taskLocker.lock();
        scope(exit) {
            _taskLocker.unlock();
        } 

        _tasks.remove(id);
    }

    void Clear() {
        _taskLocker.lock();
        scope(exit) {
            _taskLocker.unlock();
        } 
        _tasks.clear();

    }

    void Run() {
        bool r = cas(&_isRunning, false, true);
        if(r) {
            import std.parallelism;
            auto t = task(&DoRun);
            t.executeInNewThread();
        }
    }

    void Stop() {
        _isRunning = false;
        foreach(size_t index; 0 .. _size) {
            _workerThreads[index].Stop();
        }
    }

    private WorkerThread findIdleThread() {
        foreach(size_t index, WorkerThread thread; _workerThreads) {
            version(GEAR_IO_DEBUG) {
                log.trace("Thread: %s, state: %s", thread.name, thread.State);
            }

            if(thread.IsIdle())
                return thread;
        }

        return null;
    } 

    private void DoRun() {
        while(_isRunning) {
            try {
                version(GEAR_IO_DEBUG) Info("running...");
                Task task = _taskQueue.Pop();
                if(task is null) {
                    version(GEAR_IO_DEBUG) {
                        log.warning("A null task popped!");
                        Inspect();
                    }
                    continue;
                }

                WorkerThread workerThread;
                bool isAttatched = false;
                
                do {
                    workerThread = findIdleThread();

                    // All worker threads are busy!
                    if(workerThread is null) {
                        // version(GEAR_METRIC) {
                        //     _taskQueue.Inspect();
                        // }
                        // Trace("All worker threads are busy!");
                        // Thread.sleep(1.seconds);
                        // Thread.sleep(10.msecs);
                        Thread.yield();
                    } else {
                        isAttatched = workerThread.Attatch(task);
                    }
                } while(!isAttatched && _isRunning);

            } catch(Throwable ex) {
                log.warning(ex);
            }
        }

        version(GEAR_IO_DEBUG) log.warning("Worker stopped!");

    }

}

