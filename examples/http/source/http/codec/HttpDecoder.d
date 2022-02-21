module http.codec.HttpDecoder;

import gear.codec.Decoder;
import gear.codec.Encoder;
import gear.buffer.Buffer;

import gear.event;

import http.HttpRequestParser;
import http.HttpRequest;

import gear.logging;

class HttpDecoder : AbstractDecoder
{
    
    override DataHandleStatus Decode(Buffer buf)
    {
        string content = buf.toString();
        Tracef("Decoding: %s", content);

        HttpRequest request = new HttpRequest();
        auto parser = new HttpRequestParser;

        HttpRequestParser.ParseResult result = parser.parse(request, cast(ubyte[])content.dup);

        if ( result == HttpRequestParser.ParseResult.ParsingCompleted )
        {
            if(_handler !is null)
            {
                _handler(request);
            }

            return DataHandleStatus.Done;
        }

        return DataHandleStatus.Pending;
    }
}
