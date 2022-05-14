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

module gear.event.timer.Kqueue;

// dfmt off
version (HAVE_KQUEUE) : 
// dfmt on

import gear.event.selector.Selector;
import gear.Functions;
import gear.event.timer.Common;
import gear.net.channel;

import core.sys.posix.time;
import std.socket;

/**
*/
class AbstractTimer : TimerChannelBase {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        _sock = new Socket(AddressFamily.UNIX, SocketType.STREAM);
        this.handle = _sock.handle;
        _readBuffer = new UintObject();
    }

    ~this() @nogc {
        // Close();
    }

    bool readTimer(scope SimpleActionHandler read) {
        this.ClearError();
        this._readBuffer.data = 1;
        if (read)
            read(this._readBuffer);
        return false;
    }

    UintObject _readBuffer;
    Socket _sock;
}
