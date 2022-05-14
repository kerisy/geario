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

module gear.event.selector;

public import gear.event.selector.Selector;

version (HAVE_EPOLL) {
    public import gear.event.selector.Epoll;
} else version (HAVE_KQUEUE) {
    public import gear.event.selector.Kqueue;

} else version (HAVE_IOCP) {
    public import gear.event.selector.IOCP;
} else {
    static assert(false, "unsupported platform");
}
