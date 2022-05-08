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

module gear.event.timer;

public import gear.event.timer.Common;

version (HAVE_EPOLL) {
    public import gear.event.timer.Epoll;
} else version (HAVE_KQUEUE) {
    public import gear.event.timer.Kqueue;
} else version (HAVE_IOCP) {
    public import gear.event.timer.IOCP;
}
