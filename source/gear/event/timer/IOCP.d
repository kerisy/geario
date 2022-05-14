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

module gear.event.timer.IOCP;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import gear.event.selector.Selector;
import gear.event.timer.Common;
import gear.Functions;
import gear.net.channel.Types;

import core.time;

/**
*/
class AbstractTimer : TimerChannelBase {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        _timer = new GearWheelTimer();
        _timer.timeout = &onTimerTimeout;
        _readBuffer = new UintObject();
    }

    bool readTimer(scope SimpleActionHandler read) {
        this.ClearError();
        this._readBuffer.data = 1;
        if (read)
            read(this._readBuffer);
        return false;
    }

    private void onTimerTimeout(Object) {
        _timer.rest(wheelSize);
        this.OnRead();
    }

    override void Stop() {
        _timer.Stop();
        super.Stop();
    }

    bool setTimerOut() {
        if (_interval > 0) {
            _interval = _interval > 20 ? _interval : 20;
            auto size = _interval / CustomTimerMinTimeOut;
            const auto superfluous = _interval % CustomTimerMinTimeOut;
            size += superfluous > CustomTimer_Next_TimeOut ? 1 : 0;
            size = size > 0 ? size : 1;
            _wheelSize = cast(uint) size;
            _circle = _wheelSize / CustomTimerWheelSize;
            return true;
        }
        return false;
    }

    @property GearWheelTimer timer() {
        return _timer;
    }

    UintObject _readBuffer;

    private GearWheelTimer _timer;
}
