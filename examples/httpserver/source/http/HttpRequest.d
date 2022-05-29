module http.HttpRequest;

import std.container;
import std.array : Appender;

class HttpRequest
{
    struct Header
    {
        Appender!string name;
        Appender!string value;
    }

    string method;
    string uri;

    int versionMajor = 0;
    int versionMinor = 0;

    Array!Header headers;
    
    bool keepAlive = false;

    ubyte[] content;
}
