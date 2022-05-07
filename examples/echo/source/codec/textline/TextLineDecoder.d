module codec.textline.TextLineDecoder;

import gear.buffer.Buffer;

import codec.Decoder;

class TextLineDecoder : Decoder!string
{
    long Decode(ref Buffer buffer, ref string message)
    {
        ulong i = 0;

        foreach ( b; buffer.Data().data())
        {
            if (b == cast(ubyte) "\n")
            {
                message = cast(string) buffer.Data().data()[0 .. i];
                buffer.Pop(i + 1);
                break;
            }

            i++;
        }

        return i;
    }
}
