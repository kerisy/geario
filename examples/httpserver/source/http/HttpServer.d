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

module http.HttpServer;

import geario.buffer.Bytes;

import geario.event;
import geario.logging;

import geario.net.TcpListener;
import geario.net.TcpStream;

import geario.codec.Framed;

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
            log.info("new connection from: %s", connection.RemoteAddress.toString());

            auto codec = new HttpCodec();
            auto framed = codec.CreateFramed(connection);

            framed.OnFrame((HttpRequest request)
                {
                    log.trace("content: %s", request.content);
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
                    log.info("client disconnected: %s", connection.RemoteAddress.toString());
                }).Closed(() {
                    log.info("connection closed, local: %s, remote: %s",
                        connection.LocalAddress.toString(), connection.RemoteAddress.toString());
                }).Error((IoError error) { 
                    log.error("Error occurred: %d  %s", error.errorCode, error.errorMsg); 
                });
        });
    }

    void Start()
    {
        log.trace("Listening on: %s", _listener.BindingAddress.toString());

        _listener.Start();
        _loop.Run();
    }
}
