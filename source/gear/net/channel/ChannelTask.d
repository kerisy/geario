module gear.net.channel.ChannelTask;

import gear.event.selector.Selector;
import gear.Functions;
import gear.logging.ConsoleLogger;
import gear.net.channel.AbstractSocketChannel;
import gear.net.channel.Types;
import gear.net.IoError;
import gear.system.Error;
import gear.util.queue;
import gear.util.worker;

import nbuff;

import std.format;
import std.socket;

import core.atomic;

/**
 * 
 */
class ChannelTask : Task {
    DataReceivedHandler dataReceivedHandler;
    private shared bool _isFinishing = false;
    // private Queue!(NbuffChunk) _bytes;
    private Nbuff _buffers;

    this() {
        // _bytes = new SimpleQueue!(NbuffChunk);
    }

    void put(NbuffChunk bytes) {
        // _bytes.Push(bytes);
        _buffers.append(bytes);
    }

    bool IsFinishing () {
        return _isFinishing;
    }

    override protected void DoExecute() {

        NbuffChunk bytes;

        do {
            bytes = _buffers.frontChunk();
            _buffers.popChunk();

            if(bytes.empty()) {
                version(GEAR_IO_DEBUG) {
                    Warning("A null buffer poped");
                }
                break;
            }

            version(GEAR_IO_DEBUG) {
                Tracef("buffer: %s", cast(string)bytes.data);
            }

            dataReceivedHandler(bytes);

            version(GEAR_IO_DEBUG) {
                Tracef("bytes: %s", cast(string)bytes.data);
            }
            
            _isFinishing = IsTerminated();
            if(!_isFinishing) {
                _isFinishing = _buffers.empty();
            }

            if(_isFinishing) {
                version(GEAR_DEBUG) {
                    if(!bytes.empty() || !_buffers.empty()) {
                        Warningf("The buffered data lost");
                    }
                }
                break;
            }
        } while(true);
    }
}

