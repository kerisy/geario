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
    private
    {
        TcpStream _connection;
        Codec!(DT, ET) _codec;
        FrameHandle!DT _handle;

        Buffer _receivedBuffer;
        Buffer _sendBuffer;
    }

    this(TcpStream connection, Codec!(DT, ET) codec)
    {
        _codec = codec;
        _connection = connection;

        connection.Received(&Received);
        connection.Writed(&Sended);
    }

    private void Received(Bytes bytes)
    {
        _receivedBuffer.Append(bytes);

        while (true)
        {
            DT message;
            long result = _codec.decoder().Decode(_receivedBuffer, message);
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
                if (_receivedBuffer.Length() > 0)
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
    }

    private void Sended(ulong n)
    {
        Tracef("Pop bytes: %d", n);
        // _sendBuffer.Pop(bytes);
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
        _sendBuffer = _codec.encoder().Encode(message);

        // for debug
        string content = _sendBuffer.toString();
        Tracef("Writting: %s", content);

        _connection.Write(_sendBuffer.Data().data());
    }
}
