module gear.net.channel.ChannelTask;

import gear.event.selector.Selector;
import gear.Functions;
import gear.buffer.Bytes;
import gear.logging.ConsoleLogger;
import gear.net.channel.AbstractSocketChannel;
import gear.net.channel.Common;
import gear.net.IoError;
import gear.system.Error;
import gear.util.queue;
import gear.util.worker;


import std.format;
import std.socket;

import core.atomic;

/**
 * 
 */
class ChannelTask : Task {
    DataReceivedHandler dataReceivedHandler;
    private shared bool _isFinishing = false;
    private Queue!(Bytes) _bytes;

    this() {
        _bytes = new SimpleQueue!(Bytes);
    }

    void put(Bytes bytes) {
        _bytes.Push(bytes);
    }

    bool IsFinishing () {
        return _isFinishing;
    }

    override protected void DoExecute() {

        Bytes bytes;
        DataHandleStatus handleStatus = DataHandleStatus.Pending;

        do {
            bytes = _bytes.Pop();
            if(bytes.IsEmpty()) {
                version(GEAR_IO_DEBUG) {
                    Warning("A null buffer poped");
                }
                break;
            }

            version(GEAR_IO_DEBUG) {
                Tracef("buffer: %s", cast(string)bytes.AsArray.ptr);
            }

            handleStatus = dataReceivedHandler(bytes);

            version(GEAR_IO_DEBUG) {
                Tracef("Handle status: %s, bytes: %s", handleStatus, cast(string)bytes.AsArray.ptr);
            }
            
            _isFinishing = IsTerminated();
            if(!_isFinishing) {
                _isFinishing = handleStatus == DataHandleStatus.Done && _bytes.IsEmpty();
            }

            if(_isFinishing) {
                version(GEAR_DEBUG) {
                    if(!bytes.IsEmpty() || !_bytes.IsEmpty()) {
                        Warningf("The buffered data lost");
                    }
                }
                break;
            }
        } while(true);
    }
}

