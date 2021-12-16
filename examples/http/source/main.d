
import http.HttpRequest;
import http.HttpRequestParser;

import std.stdio;

void main(string[] args)
{
    enum string text = "GET /testuri HTTP/1.1\r\n" ~
                        "User-Agent: Mozilla/5.0\r\n" ~ 
                        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" ~
                        "Host: 127.0.0.1\r\n" ~
                        "\r\n";

    HttpRequest request;
    
    auto parser = new HttpRequestParser;

    HttpRequestParser.ParseResult res = parser.parse(request, cast(ubyte[])text);

    if ( res == HttpRequestParser.ParseResult.ParsingCompleted )
    {
        writeln("method: ", request.method);
        writeln("uri", request.uri);
        foreach (header; request.headers)
        {
            writeln(header.name[], ": ", header.value[]);
        }

        writeln("SUCCESS");
    }
    else
    {
        writeln("FAILED");
    }
}
