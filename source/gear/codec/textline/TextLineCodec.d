module gear.codec.textline.TextLineCodec;

import gear.codec.Codec;
import gear.codec.Encoder;
import gear.codec.Decoder;

import gear.codec.textline.TextLineDecoder;
import gear.codec.textline.TextLineEncoder;

/** 
 * 
 */
class TextLineCodec : Codec
{
    private TextLineEncoder _encoder;
    private TextLineDecoder _decoder;

    this() {
        _encoder = new TextLineEncoder();
        _decoder = new TextLineDecoder();
    }

    Encoder GetEncoder()
    {
        return _encoder;
    }

    Decoder GetDecoder()
    {
        return _decoder;
    }
}
