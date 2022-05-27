module geario.util.worker.Task;

import geario.util.queue;
import geario.logging;

import core.atomic;
import std.datetime;
import std.format;

enum TaskStatus : ubyte {
    Ready,
    Processing,
    Terminated,
    Done
}

alias TaskQueue = Queue!Task;
alias MemoryTaskQueue = SimpleQueue!Task;

/**
 * 
 */
abstract class Task {
    protected shared TaskStatus _status;

    size_t id;
    
    private MonoTime _createTime;
    private MonoTime _startTime;
    private MonoTime _endTime;

    this() {
        _status = TaskStatus.Ready;
        _createTime = MonoTime.currTime;
    }

    Duration SurvivalTime() {
        return _endTime - _createTime;
    }

    Duration ExecutionTime() {
        return _endTime - _startTime;
    }

    Duration LifeTime() {
        if(_endTime > _createTime) {
            return SurvivalTime();
        } else {
            return MonoTime.currTime - _createTime;
        }
    }

    TaskStatus Status() {
        return _status;
    }

    bool IsReady() {
        return _status == TaskStatus.Ready;
    }

    bool IsProcessing() {
        return _status == TaskStatus.Processing;
    }

    bool IsTerminated() {
        return _status == TaskStatus.Terminated;
    }

    bool IsDone() {
        return _status == TaskStatus.Done;
    }

    void Stop() {
        
        version(GEAR_IO_DEBUG) {
            log.trace("The task status: %s", _status);
        }

        if(!cas(&_status, TaskStatus.Processing, TaskStatus.Terminated) && 
            !cas(&_status, TaskStatus.Ready, TaskStatus.Terminated)) {
            version(GEAR_IO_DEBUG) {
                log.warn("The task status: %s", _status);
            }
        }
    }

    void Finish() {
        version(GEAR_IO_DEBUG) {
            log.trace("The task status: %s", _status);
        }

        if(cas(&_status, TaskStatus.Processing, TaskStatus.Done) || 
            cas(&_status, TaskStatus.Ready, TaskStatus.Done)) {
                
            _endTime = MonoTime.currTime;
            version(GEAR_IO_DEBUG) {
                log.info("The task done.");
            }
        } else {
            version(GEAR_IO_DEBUG) {
                log.warn("The task status: %s", _status);
                log.warn("Failed to set the task status to Done: %s", _status);
            }
        }
    }

    protected void DoExecute();

    void Execute() {
        if(cas(&_status, TaskStatus.Ready, TaskStatus.Processing)) {
            version(GEAR_IO_DEBUG) {
                log.trace("Task %d executing... status: %s", id, _status);
            }
            _startTime = MonoTime.currTime;
            scope(exit) {
                Finish();
                version(GEAR_IO_DEBUG) {
                    Info("Task Done!");
                }
            }
            DoExecute();
        } else {
            log.warn("Failed to Execute task %d. Its status is: %s", id, _status);
        }
    }

    override string toString() {
        return format("id: %d, status: %s", id, _status);
    }

}