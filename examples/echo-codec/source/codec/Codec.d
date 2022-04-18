module codec.Codec;

import gear.buffer.Buffer;

import gear.net.TcpStream;

public import codec.Framed;

abstract class Codec(Message)
{
    Framed CreateFramed(TcpStream conn)
    {
        auto framed = new Framed!Message(conn, this);

        return framed;
    }

    Buffer Encode(Message message);

    Message Decode(Buffer buffer);
}
