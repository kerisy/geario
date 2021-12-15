module http.HttpRequestParser;

import std.container;
import std.stdio;

import std.algorithm.comparison : equal;
import std.conv : to;
import std.algorithm.iteration : filter;
import std.uni : icmp;
import std.uni : isAlpha;
import std.array;

import core.stdc.ctype : isalnum;
import core.stdc.stdlib : strtol;

import http.HttpRequest;

class HttpRequestParser
{
    private
    {
        State _state = State.RequestMethodStart;
        size_t _contentSize = 0;
        string _chunkSizeStr;
        size_t _chunkSize = 0;
        bool _chunked = false;
    }

    public:
        this()
        {
            // What to do?
        }

        enum ParseResult {
            ParsingCompleted,
            ParsingIncompleted,
            ParsingError
        }

        ParseResult parse(ref HttpRequest req, const ubyte[] text)
        {
            return consume(req, text);
        }

private:
    static bool checkIfConnection(const HttpRequest.Header h)
    {
        return icmp(h.name[], "Connection") == 0;
    }

    ParseResult consume(ref HttpRequest req, const ubyte[] text)
    {
        foreach(input; text)
        {
            switch (_state)
            {
            case State.RequestMethodStart:
                if( !isChar(input) || isControl(input) || isSpecial(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    _state = State.RequestMethod;
                    req.method ~= input;
                }
                break;
            case State.RequestMethod:
                if( input == ' ' )
                {
                    _state = State.RequestUriStart;
                }
                else if( !isChar(input) || isControl(input) || isSpecial(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    req.method ~= input;
                }
                break;
            case State.RequestUriStart:
                if( isControl(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    _state = State.RequestUri;
                    req.uri ~= input;
                }
                break;
            case State.RequestUri:
                if( input == ' ' )
                {
                    _state = State.RequestHttpVersion_h;
                }
                else if (input == '\r')
                {
                    req.versionMajor = 0;
                    req.versionMinor = 9;

                    return ParseResult.ParsingCompleted;
                }
                else if( isControl(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    req.uri ~= input;
                }
                break;
            case State.RequestHttpVersion_h:
                if( input == 'H' )
                {
                    _state = State.RequestHttpVersion_ht;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_ht:
                if( input == 'T' )
                {
                    _state = State.RequestHttpVersion_htt;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_htt:
                if( input == 'T' )
                {
                    _state = State.RequestHttpVersion_http;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_http:
                if( input == 'P' )
                {
                    _state = State.RequestHttpVersion_slash;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_slash:
                if( input == '/' )
                {
                    req.versionMajor = 0;
                    req.versionMinor = 0;
                    _state = State.RequestHttpVersion_majorStart;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_majorStart:
                if( isDigit(input) )
                {
                    req.versionMajor = input - '0';
                    _state = State.RequestHttpVersion_major;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_major:
                if( input == '.' )
                {
                    _state = State.RequestHttpVersion_minorStart;
                }
                else if (isDigit(input))
                {
                    req.versionMajor = req.versionMajor * 10 + input - '0';
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_minorStart:
                if( isDigit(input) )
                {
                    req.versionMinor = input - '0';
                    _state = State.RequestHttpVersion_minor;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.RequestHttpVersion_minor:
                if( input == '\r' )
                {
                    _state = State.ResponseHttpVersion_newLine;
                }
                else if( isDigit(input) )
                {
                    req.versionMinor = req.versionMinor * 10 + input - '0';
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ResponseHttpVersion_newLine:
                if( input == '\n' )
                {
                    _state = State.HeaderLineStart;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.HeaderLineStart:
                if( input == '\r' )
                {
                    _state = State.ExpectingNewline_3;
                }
                else if( !req.headers.empty() && (input == ' ' || input == '\t') )
                {
                    _state = State.HeaderLws;
                }
                else if( !isChar(input) || isControl(input) || isSpecial(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    // TODO:
                    // req.headers.push_back(Request::HeaderItem());
                    // req.headers.back().name.reserve(16);
                    // req.headers.back().value.reserve(16);
                    // req.headers.back().name.push_back(input);

                    // req.headers.insertBack(HttpRequest.Header(Appender!string(""), Appender!string(input)));
                    HttpRequest.Header header;
                    header.name.put(input);
                    req.headers.insertBack(header);
                    
                    _state = State.HeaderName;
                }
                break;
            case State.HeaderLws:
                if( input == '\r' )
                {
                    _state = State.ExpectingNewline_2;
                }
                else if( input == ' ' || input == '\t' )
                {
                }
                else if( isControl(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    _state = State.HeaderValue;
                    req.headers.back.value.put(input);
                }
                break;
            case State.HeaderName:
                if( input == ':' )
                {
                    _state = State.SpaceBeforeHeaderValue;
                }
                else if( !isChar(input) || isControl(input) || isSpecial(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    req.headers.back.name.put(input);
                }
                break;
            case State.SpaceBeforeHeaderValue:
                if( input == ' ' )
                {
                    _state = State.HeaderValue;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.HeaderValue:
                if( input == '\r' )
                {
                    if( req.method == "POST" || req.method == "PUT" )
                    {
                        HttpRequest.Header h = req.headers.back;

                        if( icmp(h.name[], "Content-Length") == 0 )
                        {
                            _contentSize = h.value.data().to!int;
                            // req.content.reserve( _contentSize );
                        }
                        else if( icmp(h.name[], "Transfer-Encoding") == 0 )
                        {
                            if( icmp(h.value[], "chunked") == 0 )
                                _chunked = true;
                        }
                    }
                    _state = State.ExpectingNewline_2;
                }
                else if( isControl(input) )
                {
                    return ParseResult.ParsingError;
                }
                else
                {
                    req.headers.back.value.put(input);
                }
                break;
            case State.ExpectingNewline_2:
                if( input == '\n' )
                {
                    _state = State.HeaderLineStart;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ExpectingNewline_3: {
                auto it = filter!(a => checkIfConnection(a))(req.headers.array);

                if(!it.empty() )
                {
                    HttpRequest.Header header = it.front;
                    if( icmp(header.value.data(), "Keep-Alive") == 0 )
                    {
                        req.keepAlive = true;
                    }
                    else  // == Close
                    {
                        req.keepAlive = false;
                    }
                }
                else
                {
                    if( req.versionMajor > 1 || (req.versionMajor == 1 && req.versionMinor == 1) )
                        req.keepAlive = true;
                }

                if( _chunked )
                {
                    _state = State.ChunkSize;
                }
                else if( _contentSize == 0 )
                {
                    if( input == '\n')
                        return ParseResult.ParsingCompleted;
                    else
                        return ParseResult.ParsingError;
                }
                else
                {
                    _state = State.Post;
                }
                break;
            }
            case State.Post:
                --_contentSize;
                req.content ~= input;

                if( _contentSize == 0 )
                {
                    return ParseResult.ParsingCompleted;
                }
                break;
            case State.ChunkSize:
                if( isalnum(input) )
                {
                    _chunkSizeStr ~= input;
                }
                else if( input == ';' )
                {
                    _state = State.ChunkExtensionName;
                }
                else if( input == '\r' )
                {
                    _state = State.ChunkSizeNewLine;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkExtensionName:
                if( isalnum(input) || input == ' ' )
                {
                    // skip
                }
                else if( input == '=' )
                {
                    _state = State.ChunkExtensionValue;
                }
                else if( input == '\r' )
                {
                    _state = State.ChunkSizeNewLine;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkExtensionValue:
                if( isalnum(input) || input == ' ' )
                {
                    // skip
                }
                else if( input == '\r' )
                {
                    _state = State.ChunkSizeNewLine;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkSizeNewLine:
                if( input == '\n' )
                {
                    _chunkSize = strtol(_chunkSizeStr.ptr, null, 16);
                    // _chunkSizeStr.clear();
                    // req.content.reserve(strlen(req.content) + _chunkSize);

                    if( _chunkSize == 0 )
                        _state = State.ChunkSizeNewLine_2;
                    else
                        _state = State.ChunkData;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkSizeNewLine_2:
                if( input == '\r' )
                {
                    _state = State.ChunkSizeNewLine_3;
                }
                else if( isAlpha(input) )
                {
                    _state = State.ChunkTrailerName;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkSizeNewLine_3:
                if( input == '\n' )
                {
                    return ParseResult.ParsingCompleted;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                // break;
            case State.ChunkTrailerName:
                if( isalnum(input) )
                {
                    // skip
                }
                else if( input == ':' )
                {
                    _state = State.ChunkTrailerValue;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkTrailerValue:
                if( isalnum(input) || input == ' ' )
                {
                    // skip
                }
                else if( input == '\r' )
                {
                    _state = State.ChunkSizeNewLine;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkData:
                req.content ~= input;

                if( --_chunkSize == 0 )
                {
                    _state = State.ChunkDataNewLine_1;
                }
                break;
            case State.ChunkDataNewLine_1:
                if( input == '\r' )
                {
                    _state = State.ChunkDataNewLine_2;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            case State.ChunkDataNewLine_2:
                if( input == '\n' )
                {
                    _state = State.ChunkSize;
                }
                else
                {
                    return ParseResult.ParsingError;
                }
                break;
            default:
                return ParseResult.ParsingError;
            }
        }

        return ParseResult.ParsingIncompleted;
    }

    // Check if a byte is an HTTP character.
    bool isChar(int c)
    {
        return c >= 0 && c <= 127;
    }

    // Check if a byte is an HTTP control character.
    bool isControl(int c)
    {
        return (c >= 0 && c <= 31) || (c == 127);
    }

    // Check if a byte is defined as an HTTP special character.
    bool isSpecial(int c)
    {
        switch (c)
        {
        case '(': case ')': case '<': case '>': case '@':
        case ',': case ';': case ':': case '\\': case '"':
        case '/': case '[': case ']': case '?': case '=':
        case '{': case '}': case ' ': case '\t':
            return true;
        default:
            return false;
        }
    }

    // Check if a byte is a digit.
    bool isDigit(int c)
    {
        return c >= '0' && c <= '9';
    }

    // The current state of the parser.
    enum State
    {
        RequestMethodStart,
        RequestMethod,
        RequestUriStart,
        RequestUri,
        RequestHttpVersion_h,
        RequestHttpVersion_ht,
        RequestHttpVersion_htt,
        RequestHttpVersion_http,
        RequestHttpVersion_slash,
        RequestHttpVersion_majorStart,
        RequestHttpVersion_major,
        RequestHttpVersion_minorStart,
        RequestHttpVersion_minor,

        ResponseStatusStart,
        ResponseHttpVersion_ht,
        ResponseHttpVersion_htt,
        ResponseHttpVersion_http,
        ResponseHttpVersion_slash,
        ResponseHttpVersion_majorStart,
        ResponseHttpVersion_major,
        ResponseHttpVersion_minorStart,
        ResponseHttpVersion_minor,
        ResponseHttpVersion_spaceAfterVersion,
        ResponseHttpVersion_statusCodeStart,
        ResponseHttpVersion_spaceAfterStatusCode,
        ResponseHttpVersion_statusTextStart,
        ResponseHttpVersion_newLine,

        HeaderLineStart,
        HeaderLws,
        HeaderName,
        SpaceBeforeHeaderValue,
        HeaderValue,
        ExpectingNewline_2,
        ExpectingNewline_3,

        Post,
        ChunkSize,
        ChunkExtensionName,
        ChunkExtensionValue,
        ChunkSizeNewLine,
        ChunkSizeNewLine_2,
        ChunkSizeNewLine_3,
        ChunkTrailerName,
        ChunkTrailerValue,

        ChunkDataNewLine_1,
        ChunkDataNewLine_2,
        ChunkData,
    }
}
