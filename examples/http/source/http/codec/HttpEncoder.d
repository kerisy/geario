module http.codec.HttpEncoder;

import gear.codec.Encoder;

import gear.buffer.Buffer;

import http.HttpRequest;
import http.HttpResponse;

class HttpEncoder : AbstractEncoder
{

    override Buffer Encode(Object message)
    {
        HttpResponse response = cast(HttpResponse)message;
        assert(response !is null);

        // TODO: HttpResponse object serialize to string

        return Buffer("Hello world");
    }
}
