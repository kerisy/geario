module codec.textline.TextLineEncoder;

import gear.buffer.Buffer;

import codec.Encoder;

class TextLineEncoder : Encoder!string
{
    Buffer Encode(string message)
    {
        Buffer buf;
        buf.Append(message);

        return buf;
    }
}
