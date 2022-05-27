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

module geario.codec.Framed;

import nbuff;

import geario.codec.Codec;

import geario.net.TcpStream;
import geario.net.channel.Types;

import geario.logging;

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

        Nbuff _receivedBuffer;
        Nbuff _sendBuffer;
    }

    this(TcpStream connection, Codec!(DT, ET) codec)
    {
        _codec = codec;
        _connection = connection;

        connection.Received(&Received);
        connection.Writed(&Sended);
    }

    private void Received(NbuffChunk bytes)
    {
        // log.trace(cast(string) bytes.data());
        _receivedBuffer.append(bytes);

        while (true)
        {
            DT message;
            long result = _codec.decoder().Decode(_receivedBuffer, message);
            if (result == -1)
            {
                log.error("decode error, close the connection.");
                _connection.Close();
                break;
            }

            // Multiple messages, continue decode
            if (result > 0)
            {
                Handle(message);
                if (_receivedBuffer.length() > 0)
                    continue;
                else
                    break;
            }

            if (result == 0)
            {
                // log.warning("waiting data ..");
                break;
            }
        }
    }

    private void Sended(ulong n)
    {
        // if (_sendBuffer.length() >= n)
        // {
        //     version(GEAR_IO_DEBUG) log.trace("Pop bytes: %d", n);

        //     _sendBuffer.pop(n);
        // }
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
        NbuffChunk bytes = _codec.encoder().Encode(message);

        version(GEAR_IO_DEBUG) log.trace("Sending bytes: %d", bytes.length());

        _connection.Write(bytes);
    }
}
