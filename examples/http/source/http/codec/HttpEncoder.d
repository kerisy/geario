module http.codec.HttpEncoder;

import gear.codec.Encoder;

import http.HttpRequest;
import http.HttpResponse;

enum string ResponseContent = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Hunt/1.0\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, world!";

class HttpEncoder : Encoder!HttpResponse
{

    override Buffer Encode(HttpResponse response)
    {
        // TODO: HttpResponse object serialize to string

        return Buffer(ResponseContent);
    }
}
