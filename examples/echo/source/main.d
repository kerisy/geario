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

import gear.buffer.Bytes;

import gear.codec.textline.TextLineCodec;
import gear.codec.textline.TextLineDecoder;
import gear.codec;

import gear.event;
import gear.logging.ConsoleLogger;

import gear.net.TcpListener;
import gear.net.TcpStream;

void main()
{
    EventLoop loop = new EventLoop();

    TcpListener listener = new TcpListener(loop);

    listener.Bind(8888)
        .Accepted((TcpListener sender, TcpStream connection)
        {
            Infof("new connection from: %s", connection.RemoteAddress.toString());

            if (1)
            {
                Framed!(TextLineFrame) framed = new Framed!(TextLineFrame)(connection, new TextLineCodec());

                framed.OnFrame((TextLineFrame frame)
                    {
                        Tracef("Line: %s", frame.line);

                        connection.Write(cast(ubyte[])frame.line.dup);
                    });
            }
            else
            {
                connection.Received((Bytes bytes)
                    {
                        Infof("%s", bytes.Chunk());

                        connection.Write(bytes);
                        return DataHandleStatus.Done;
                    });
            }

            connection.Disconnected(() {
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
