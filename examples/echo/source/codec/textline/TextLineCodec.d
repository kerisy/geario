module codec.textline.TextLineCodec;

import codec.Codec;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

import codec.textline.TextLineDecoder;
import codec.textline.TextLineEncoder;

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
