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

module gear.codec.textline.TextLineCodec;

import gear.codec.Codec;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

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
