module http.HttpResponse;

class HttpResponse
{
    int versionMajor = 0;
    int versionMinor = 0;
    string[][string] headers;
    ubyte[] content;
    bool keepAlive = false;
    
    ushort statusCode = 0;
    string status;
}
