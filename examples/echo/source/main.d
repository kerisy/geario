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

import std.stdio;

import geario.codec.textline.TextLineCodec;

import geario.event;
import geario.logging;

import geario.net.TcpListener;
import geario.net.TcpStream;

void main()
{
    EventLoop loop = new EventLoop();

    TcpListener listener = new TcpListener(loop);

    listener.Bind(8888)
        .Accepted((TcpListener sender, TcpStream conn)
        {
            Infof("new connection from: %s", conn.RemoteAddress.toString());

            // new TextLineCodec for string
            auto codec = new TextLineCodec;

            // Create string typed framed from Codec
            auto framed = codec.CreateFramed(conn);

            // Set OnFrame callback function for string message
            framed.OnFrame((string message) {

                Tracef("Message: %s", message);

                framed.Send(message);
            });
        }).Error((IoError error) {
            writefln("Error occurred: %d  %s", error.errorCode, error.errorMsg);
        }).Start();

    writeln("Listening on: ", listener.BindingAddress.toString());
    loop.Run();
}
