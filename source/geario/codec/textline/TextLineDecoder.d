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

module geario.codec.textline.TextLineDecoder;

import nbuff;

import geario.codec.Decoder;
import geario.logging;

import std.conv : to;

class TextLineDecoder : Decoder!string
{
    long Decode(ref Nbuff buffer, ref string message)
    {
        ulong n = 0;

        foreach ( b; cast(string) buffer.data().data() )
        {
            n++;

            if (b.to!string == "\n")
            {
                message = cast(string) buffer.data().data()[0 .. n];
                buffer.pop(n);

                return n;
            }
        }

        return 0;
    }
}
