/*
 * Gear - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.codec.textline.TextLineDecoder;

import nbuff;

import gear.codec.Decoder;

import std.conv : to;

class TextLineDecoder : Decoder!string
{
    long Decode(ref Nbuff buffer, ref string message)
    {
        ulong i = 0;

        foreach ( b; cast(string) buffer.data().data() )
        {
            if (b.to!string == "\n")
            {
                message = cast(string) buffer.data().data()[0 .. i];
                buffer.pop(i + 1);
                break;
            }

            i++;
        }

        return i;
    }
}
