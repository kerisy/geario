module http.HttpRequest;

import std.container;
import std.array : Appender;

struct HttpRequest
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
    ubyte[] content;
    bool keepAlive = false;

    // string inspect() const
    // {
    //     stringstream stream;
    //     stream << method << " " << uri << " HTTP/"
    //            << versionMajor << "." << versionMinor << "\n";

    //     for(std::vector<Request::HeaderItem>::const_iterator it = headers.begin();
    //         it != headers.end(); ++it)
    //     {
    //         stream << it->name << ": " << it->value << "\n";
    //     }

    //     string data(content.begin(), content.end());
    //     stream << data << "\n";
    //     stream << "+ keep-alive: " << keepAlive << "\n";;
    //     return stream.str();
    // }
}
