module geario.logging.config;

@safe:
public:

struct LoggerConfig
{
    string filename      = "./log.log";
    string level         = "trace";
    string appenderType = "ConsoleAppender";
    string rollingType   = "SizeBasedRollover";
    uint   maxSize       = 1024 * 1024 * 20;
    uint   maxHistory    = 1024;
}

/*
 * Make class member with getter
 */
template addVal(T, string name, string specificator)
{
    const char[] member = "private " ~ T.stringof ~ " _" ~ name ~"; ";
    const char[] getter = "@property nothrow pure " ~ specificator ~ " " ~ T.stringof ~ " " ~ name ~ "() { return _" ~ name ~ "; }";
    const char[] addVal = member ~ getter;
}

/**
 * Make class member with getter and setter
 *
 */
template addVar(T, string name, string getterSpecificator, string setterSpecificator)
{
    const char[] setter = "@property nothrow pure " ~ setterSpecificator ~ " void " ~ name ~ "(" ~ T.stringof ~ " var" ~ ") { _" ~ name ~ " = var; }";
    const char[] addVar = addVal!(T, name, getterSpecificator) ~ setter;
}

/**
 * Logger exception
 */
class LoggerException : Exception
{
    @safe pure nothrow this(string exString)
    {
        super(exString);
    }
}

/**
 * Log creation exception
 */
class LoggerCreateException : LoggerException
{
    @safe pure nothrow this(string exString)
    {
        super(exString);
    }
}

/*
 * Level type
 */
enum Level:int
{
    Trace = 1,
    Info = 2,
    Warn = 3,
    Error = 4,
    Fatal = 5
}

/*
 * Convert level from string type to Level
 */
Level toLevel(string str)
{
    Level l;

    switch (str)
    {
        case "trace":
            l = Level.Trace;
            break;
        case "info":
            l = Level.Info;
            break;
        case "warn":
            l = Level.Warn;
            break;
        case "error":
            l = Level.Error;
            break;
        case "fatal":
            l = Level.Fatal;
            break;
        default:
            throw new LoggerCreateException("Error log level value: " ~ str);
    }

    return l;
}

/*
 * Convert level from Level type to string
 */
@safe
string levelToViewString(Level level)
{
    string l;

    final switch (level)
    {
        case Level.Trace:
            l = "TRACE";
            break;
        case Level.Info:
            l = "INFO";
            break;
        case Level.Warn:
            l = "WARN";
            break;
        case Level.Error:
            l = "ERROR";
            break;
        case Level.Fatal:
            l = "FATAL";
            break;
    }

    return l;
}

