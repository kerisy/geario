module http.codec.HttpCodec;

import gear.codec.Codec;
import gear.codec.Encoder;
import gear.codec.Decoder;

import http.codec.HttpDecoder;
import http.codec.HttpEncoder;

/** 
 * 
 */
class HttpCodec : Codec
{
    private HttpEncoder _encoder;
    private HttpDecoder _decoder;

    this() {
        _encoder = new HttpEncoder();
        _decoder = new HttpDecoder();
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
