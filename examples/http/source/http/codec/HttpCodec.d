module http.codec.HttpCodec;

import gear.codec.Codec;
import gear.codec.Encoder;
import gear.codec.Decoder;

import http.codec.HttpDecoder;
import http.codec.HttpEncoder;

import http.HttpRequest;
import http.HttpResponse;

/** 
 * 
 */
class HttpCodec : Codec!(HttpRequest, HttpResponse)
{
    private HttpEncoder _encoder;
    private HttpDecoder _decoder;

    this() {
        _encoder = new HttpEncoder();
        _decoder = new HttpDecoder();
    }

    override Decoder!HttpRequest decoder()
    {
        return _decoder;
    }

    override Encoder!HttpResponse encoder()
    {
        return _encoder;
    }
}
