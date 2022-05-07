module codec.Codec;

import gear.buffer.Bytes;
import gear.buffer.Buffer;

import gear.net.TcpStream;

public import codec.Framed;
public import codec.Encoder;
public import codec.Decoder;

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
