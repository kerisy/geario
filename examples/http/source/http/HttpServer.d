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

module http.HttpServer;

import gear.buffer.Bytes;

import gear.event;
import gear.logging.ConsoleLogger;

import gear.net.TcpListener;
import gear.net.TcpStream;

import gear.codec.Framed;

import http.codec.HttpCodec;

import http.HttpRequest;
import http.HttpResponse;

class HttpServer
{
    private
    {
        TcpListener _listener;
        EventLoop _loop;
    }

    this()
    {
        _loop = new EventLoop();
        _listener = new TcpListener(_loop);
    }

    void Listen(ushort port)
    {
        _listener.Bind(port);
        _listener.Accepted((TcpListener sender, TcpStream connection) {
            Infof("new connection from: %s", connection.RemoteAddress.toString());

            auto codec = new HttpCodec();
            auto framed = codec.CreateFramed(connection);

            framed.OnFrame((HttpRequest request)
                {
                    Tracef("content: %s", request.content);
                    HttpResponse response = new HttpResponse();
                    string path = request.uri;
                    if(path == "/plaintext")
                    {
                        response.headers["Content-Type"] = ["text/plain"];
                        response.content = cast(ubyte[])"Hello, World!".dup;
                    }

                    framed.Send(response);
                });

            connection.Disconnected(() {
                    Infof("client disconnected: %s", connection.RemoteAddress.toString());
                }).Closed(() {
                    Infof("connection closed, local: %s, remote: %s",
                        connection.LocalAddress.toString(), connection.RemoteAddress.toString());
                }).Error((IoError error) { 
                    Errorf("Error occurred: %d  %s", error.errorCode, error.errorMsg); 
                });
        });
    }

    void Start()
    {
        Tracef("Listening on: %s", _listener.BindingAddress.toString());

        _listener.Start();
        _loop.Run();
    }
}
