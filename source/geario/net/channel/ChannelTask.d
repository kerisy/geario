module geario.net.channel.ChannelTask;

import geario.event.selector.Selector;
import geario.Functions;
import geario.logging;
import geario.net.channel.AbstractSocketChannel;
import geario.net.channel.Types;
import geario.net.IoError;
import geario.system.Error;
import geario.util.queue;
import geario.util.worker;

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
                    log.warn("A null buffer poped");
                }
                break;
            }

            version(GEAR_IO_DEBUG) {
                log.trace("buffer: %s", cast(string)bytes.data);
            }

            dataReceivedHandler(bytes);

            version(GEAR_IO_DEBUG) {
                log.trace("bytes: %s", cast(string)bytes.data);
            }
            
            _isFinishing = IsTerminated();
            if(!_isFinishing) {
                _isFinishing = _buffers.empty();
            }

            if(_isFinishing) {
                version(GEAR_DEBUG) {
                    if(!bytes.empty() || !_buffers.empty()) {
                        log.warn("The buffered data lost");
                    }
                }
                break;
            }
        } while(true);
    }
}

