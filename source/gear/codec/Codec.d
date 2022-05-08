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

module gear.codec.Codec;

import gear.buffer.Bytes;
import gear.buffer.Buffer;

import gear.net.TcpStream;

public import gear.codec.Framed;
public import gear.codec.Encoder;
public import gear.codec.Decoder;

/**
 * DT: Decode Template
 * ET: Encode Template
 */
abstract class Codec(DT, ET)
{
    Framed!(DT, ET) CreateFramed(TcpStream conn)
    {
        auto framed = new Framed!(DT, ET)(conn, this);

        return framed;
    }

    // -1 : Failed
    //  0 : Partial
    // >0 : Parsed length
    Decoder!DT decoder();

    Encoder!ET encoder();
}
