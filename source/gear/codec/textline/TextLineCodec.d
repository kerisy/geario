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

module gear.codec.textline.TextLineCodec;

import gear.codec.Codec;

import nbuff;

import gear.codec.textline.TextLineDecoder;
import gear.codec.textline.TextLineEncoder;

class TextLineCodec : Codec!(string, string)
{
    private
    {
        TextLineDecoder _decoder;
        TextLineEncoder _encoder;
    }

    this()
    {
        _decoder = new TextLineDecoder;
        _encoder = new TextLineEncoder;
    }

    override TextLineDecoder decoder()
    {
        return _decoder;
    }

    override TextLineEncoder encoder()
    {
        return _encoder;
    }
}
