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

import nbuff;

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
        _receivedBuffer.append(bytes);

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
                if (_receivedBuffer.length() > 0)
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
        // if (_sendBuffer.length() >= n)
        // {
        //     version(GEAR_IO_DEBUG) Tracef("Pop bytes: %d", n);

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

        version(GEAR_IO_DEBUG) Tracef("Sending bytes: %d", bytes.length());

        _connection.Write(bytes);
    }
}
