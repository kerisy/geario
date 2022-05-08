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

module gear.codec.textline.TextLineDecoder;

import gear.buffer.Buffer;

import gear.codec.Decoder;

import std.conv : to;

class TextLineDecoder : Decoder!string
{
    long Decode(ref Buffer buffer, ref string message)
    {
        ulong i = 0;

        foreach ( b; buffer.Data().data() )
        {
            if (b == "\n".to!(immutable(ubyte)))
            {
                message = cast(string) buffer.Data().data()[0 .. i];
                buffer.Pop(i + 1);
                break;
            }

            i++;
        }

        return i;
    }
}
