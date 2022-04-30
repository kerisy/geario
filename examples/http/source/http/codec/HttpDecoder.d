module http.codec.HttpDecoder;

import gear.codec.Decoder;
import gear.codec.Encoder;
import gear.buffer.Buffer;
import gear.buffer.Bytes;

import gear.event;

import http.HttpRequestParser;
import http.HttpRequest;

import gear.logging;

class HttpDecoder : AbstractDecoder
{
    
    override void Decode(Bytes bytes)
    {
        // FIXME: Needing refactor or cleanup -@zhangxueping at 2022-04-30T11:58:30+08:00
        // 
        Buffer buf;
        buf.Append(bytes);

        string content = buf.toString();
        Tracef("Decoding: %s", content);

        HttpRequest request = new HttpRequest();
        auto parser = new HttpRequestParser;

        // HttpRequestParser.ParseResult result = parser.parse(request, cast(ubyte[])content.dup);
        HttpRequestParser.ParseResult result = parser.parse(request, cast(ubyte[])content);

        if ( result == HttpRequestParser.ParseResult.ParsingCompleted )
        {
            if(_handler !is null)
            {
                _handler(request);
            }

            if (request.keepAlive)
            {
                // TODO: set disconnect after sending
            }

        }

    }
}
