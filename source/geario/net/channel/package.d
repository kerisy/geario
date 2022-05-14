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

module geario.net.channel;

public import geario.net.channel.AbstractChannel;
public import geario.net.channel.AbstractSocketChannel;
public import geario.net.channel.Types;

version (Posix) {
    public import geario.net.channel.posix;
} else version (Windows) {
    public import geario.net.channel.iocp;
}
