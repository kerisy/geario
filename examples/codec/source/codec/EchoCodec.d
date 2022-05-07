module codec.EchoCodec;

import codec.Codec;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

class EchoCodec : Codec!string
{
    override long Decode(Buffer buffer, ref string message)
    {
        long length = buffer.Data().length();
        message = cast(string) buffer.Data().data();
        
        return length;
    }

    override Buffer Encode(string message)
    {
        Buffer buf;
        buf.Append(message);

        return buf;
    }
}
