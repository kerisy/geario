/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.net.channel.Types;

import gear.net.IoError;
import gear.buffer.Bytes;
//import gear.net.SimpleQueue;
import gear.util.queue.SimpleQueue;
import gear.Functions;
import gear.system.Memory;
import gear.logging.Logger;

import core.atomic;
import std.socket;


enum DataHandleStatus {
    Done,
    Pending
}


alias DataReceivedHandler = DataHandleStatus delegate(Bytes bytes);
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



alias WritingBufferQueue = SimpleQueue!Bytes;

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
