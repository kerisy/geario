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

module geario.codec.textline.TextLineEncoder;

import nbuff;

import geario.codec.Encoder;

class TextLineEncoder : Encoder!string
{
    NbuffChunk Encode(string message)
    {
        return NbuffChunk(message);
    }
}
