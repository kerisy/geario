module codec.EchoCodec;

import codec.Codec;

class EchoCodec : Codec!string
{
    override Buffer Encode(string message)
    {
        return;
    }

    override string Decode(Buffer buffer)
    {
        return;
    }
}
