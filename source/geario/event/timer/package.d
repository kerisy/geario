/*
 * Geario - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module geario.event.timer;

public import geario.event.timer.Common;

version (HAVE_EPOLL) {
    public import geario.event.timer.Epoll;
} else version (HAVE_KQUEUE) {
    public import geario.event.timer.Kqueue;
} else version (HAVE_IOCP) {
    public import geario.event.timer.IOCP;
}
