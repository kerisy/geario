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

module gear.codec.textline.TextLineEncoder;

import gear.buffer.Buffer;

import gear.codec.Encoder;

class TextLineEncoder : Encoder!string
{
    Buffer Encode(string message)
    {
        Buffer buf;
        buf.Append(message);

        return buf;
    }
}
