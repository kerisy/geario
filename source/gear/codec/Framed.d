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

module gear.codec.Framed;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

import gear.codec.Codec;

import gear.net.TcpStream;
import gear.net.channel.Types;

import gear.logging.ConsoleLogger;

alias FrameHandle(DT) = void delegate(DT bufer);

/**
 * DT: Decode Template
 * ET: Encode Template
 */
class Framed(DT, ET)
{
    private TcpStream _connection;
    private Codec!(DT, ET) _codec;
    private FrameHandle!DT _handle;
    private Buffer _buffer;

    this(TcpStream connection, Codec!(DT, ET) codec)
    {
        _codec = codec;
        _connection = connection;

        connection.Received((Bytes bytes)
        {
            _buffer.Append(bytes);

            while (true)
            {
                DT message;
                long result = codec.decoder().Decode(_buffer, message);
                if (result == -1)
                {
                    Errorf("decode error, close the connection.");
                    _connection.Close();
                    break;
                }

                // Multiple messages, continue decode
                if (result > 0)
                {
                    Handle(message);
                    if (_buffer.Length() > 0)
                        continue;
                    else
                        break;
                }

                if (result == 0)
                {
                    Warningf("waiting data ..");
                    break;
                }
            }
        });
    }

    void Handle(DT message)
    {
        if (_handle !is null)
        {
            _handle(message);
        }
    }

    void OnFrame(FrameHandle!DT handle)
    {
        _handle = handle;
    }

    void Send(ET message)
    {
        Buffer buf = _codec.encoder().Encode(message);

        // for debug
        string content = buf.toString();
        Tracef("Writting: %s", content);

        _connection.Write(buf.Data.data());
    }
}
