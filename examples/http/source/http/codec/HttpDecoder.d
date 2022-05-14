module http.codec.HttpDecoder;

import geario.codec.Decoder;
import geario.codec.Encoder;

import geario.event;

import http.HttpRequestParser;
import http.HttpRequest;

import geario.logging;

class HttpDecoder : Decoder!HttpRequest
{
    HttpRequestParser parser = new HttpRequestParser;
    
    override long Decode(ref Buffer buffer, ref HttpRequest request)
    {
        request = new HttpRequest;
        HttpRequestParser.ParseResult result = parser.parse(request, cast(ubyte[])buffer.toString());

        if ( result == HttpRequestParser.ParseResult.ParsingCompleted )
        {
            long length = buffer.Length();
            buffer.Clear();

            return length;
        }
        else if ( result == HttpRequestParser.ParseResult.ParsingIncompleted )
        {
            return 0;
        }
        else
        {
            return -1;
        }
    }
}
