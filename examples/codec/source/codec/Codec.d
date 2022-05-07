module codec.Codec;

import gear.buffer.Bytes;
import gear.buffer.Buffer;

import gear.net.TcpStream;

public import codec.Framed;

abstract class Codec(Message)
{
    Framed!Message CreateFramed(TcpStream conn)
    {
        auto framed = new Framed!Message(conn, this);

        return framed;
    }

    long Decode(Buffer buffer, ref Message message);

    Buffer Encode(Message message);
}
