/*
 * Archttp - A highly performant web framework written in D.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module geario.net.channel.Types;

import geario.net.IoError;
import geario.util.queue.SimpleQueue;
import geario.Functions;
import geario.system.Memory;
import geario.logging.Logger;

import core.atomic;
import std.socket;

import nbuff;

alias DataSendedHandler = void delegate(ulong n);
alias DataReceivedHandler = void delegate(NbuffChunk bytes);
alias AcceptHandler = void delegate(Socket socket);
alias ErrorEventHandler = Action1!(IoError);

alias ConnectionHandler = void delegate(bool isSucceeded);
alias UdpDataHandler = void delegate(const(ubyte)[] data, Address addr);


/**
*/
interface Channel {

}



enum ChannelType : ubyte {
    Accept = 0,
    TCP,
    UDP,
    Timer,
    Event,
    File,
    None
}

enum ChannelFlag : ushort {
    None = 0,
    Read,
    Write,

    OneShot = 8,
    ETMode = 16
}

final class UdpDataObject {
    Address addr;
    ubyte[] data;
}

final class BaseTypeObject(T) {
    T data;
}



// alias WritingBufferQueue = SimpleQueue!NbuffChunk;

/**
*/
Address CreateAddress(AddressFamily family = AddressFamily.INET,
        ushort port = InternetAddress.PORT_ANY) {
    if (family == AddressFamily.INET6) {
        // addr = new Internet6Address(port); // bug on windows
        return new Internet6Address("::", port);
    } else
        return new InternetAddress(port);
}
