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

module geario.codec.Codec;

import nbuff;

import geario.net.TcpStream;

public import geario.codec.Framed;
public import geario.codec.Encoder;
public import geario.codec.Decoder;

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
