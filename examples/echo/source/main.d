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

import std.stdio;

import gear.buffer.Buffer;
import gear.codec.textline.TextLineCodec;
import gear.codec.textline.TextLineDecoder;
import gear.codec;
import gear.event;
import gear.logging.ConsoleLogger;
import gear.net.TcpListener;
import gear.net.TcpStream;
import gear.net.IoError;
import gear.util.ThreadHelper;
import gear.util.worker;
import gear.buffer.Bytes;

// import std.socket;
// import std.functional;
// import std.exception;
// import std.datetime;
// import std.process;

// import core.thread;

void main()
{
    debug Tracef("Main thread: %s", GetTid());

    // MemoryTaskQueue memoryQueue = new MemoryTaskQueue();
    // Worker worker = new Worker(memoryQueue, 16);
    // worker.Run();
    EventLoop loop = new EventLoop();

    TcpListener listener = new TcpListener(loop);

    // dfmt off
    listener.Bind(8080)
        .Listen(1024)
        .Accepted((TcpListener sender, TcpStream connection) {
            Infof("new connection from: %s", connection.RemoteAddress.toString());

            Framed!(TextLineFrame) framed = new Framed!(TextLineFrame)(connection, new TextLineCodec());

            framed.OnFrame((TextLineFrame frame) {
                Tracef("Line: %s", frame.line);
            });

            connection.Received((Bytes bytes) {
                    connection.Write(bytes);
                    return DataHandleStatus.Done;
                }).Disconnected(() {
                    Infof("client disconnected: %s", connection.RemoteAddress.toString());
                }).Closed(() {
                    Infof("connection closed, local: %s, remote: %s",
                        connection.LocalAddress.toString(), connection.RemoteAddress.toString());
                }).Error((IoError error) { 
                    Errorf("Error occurred: %d  %s", error.errorCode, error.errorMsg); 
                });
        }).Error((IoError error) {
            writefln("Error occurred: %d  %s", error.errorCode, error.errorMsg);
        }).Start();

    // dfmt on

    writeln("Listening on: ", listener.BindingAddress.toString());
    loop.Run();
}
