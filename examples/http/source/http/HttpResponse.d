module http.HttpResponse;

struct Response
{
    int versionMajor = 0;
    int versionMinor = 0;
    string[][string] headers;
    ubyte[] content;
    bool keepAlive = false;
    
    ushort statusCode = 0;
    string status;

    // string inspect() const
    // {
    //     stringstream stream;
    //     stream << "HTTP/" << versionMajor << "." << versionMinor
    //            << " " << statusCode << " " << status << "\n";

    //     for(std::vector<Response::HeaderItem>::const_iterator it = headers.begin();
    //         it != headers.end(); ++it)
    //     {
    //         stream << it->name << ": " << it->value << "\n";
    //     }

    //     string data(content.begin(), content.end());
    //     stream << data << "\n";
    //     return stream.str();
    // }
}
