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

module gear.net.channel;

public import gear.net.channel.AbstractChannel;
public import gear.net.channel.AbstractSocketChannel;
public import gear.net.channel.Types;

version (Posix) {
    public import gear.net.channel.posix;
} else version (Windows) {
    public import gear.net.channel.iocp;
}
