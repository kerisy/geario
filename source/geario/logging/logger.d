module geario.logging.logger;

import geario.logging.config;

@safe:
public:

@property @system Logger log()
{
    if (_defaultGlobalLogger is null)
    {
        _defaultGlobalLogger = new Logger;
    }

    return _defaultGlobalLogger;
}

/**
 * Create loggers
 *
 * Throws: ConfException, LogCreateException, Exception
 */
@trusted
void create(string loggerName)
{
    if (loggerName in _loggers)
    {
        throw new LoggerCreateException("Creating logger error. Logger with name: " ~ loggerName ~ " already created");
    }
    
    _loggers[loggerName] = new Logger(loggerName);
}

/**
 * Delete logger
 *
 * Throws: Exception
 */
@trusted
void remove(immutable string loggerName)
{
    synchronized (lock)
    {
        _loggers.remove(loggerName);
    }
}

/**
 * Get created logger
 *
 * Throws: LogException
 */
@trusted
Logger get(immutable string loggerName)
{
    if (loggerName in _loggers)
    {
        return _loggers[loggerName];
    }
    else
    {
        throw new LoggerException("Getting logger error. Logger with name: " ~ loggerName ~ " not created");
    }
}

/**
 * Check Logger
 */
@trusted
bool isCreated(immutable string loggerName) nothrow
{
    return (loggerName in _loggers) ? true : false;
}

/**
 * Set file for save loggers exception information
 *
 * Throws: Exception
 */
@trusted
void setErrorFile(immutable string file)
{
    synchronized (lock)
    {
        static import geario.logging.storage;
        geario.logging.storage.createPath(file);
        errorFile = File(file, "a");
    }
}

/*
 * Logger implementation
 */
class Logger
{

public:
    /*
     * Write message with level "trace" to logger
     */
    void trace(string file = __FILE__ , size_t line = __LINE__ , M...)(lazy const M msg) nothrow
    {
        putMsg(file, line, Level.Trace, msg);
    }

    /*
     * Write message with level "info" to logger
     */
    void info(string file = __FILE__ , size_t line = __LINE__ , M...)(lazy const M msg) nothrow
    {
        putMsg(file, line, Level.Info, msg);
    }

    /*
     * Write message with level "warn" to logger
     */
    void warn(string file = __FILE__ , size_t line = __LINE__ , M...)(lazy const M msg) nothrow
    {
        putMsg(file, line, Level.Warn, msg);
    }

    /*
     * Write message with level "error" to logger
     */
    void error(string file = __FILE__ , size_t line = __LINE__ , M...)(lazy const M msg) nothrow
    {
        putMsg(file, line, Level.Error, msg);
    }

    /*
     * Write message with level "critical" to logger
     */
    void critical(string file = __FILE__ , size_t line = __LINE__ , M...)(lazy const M msg) nothrow
    {
        putMsg(file, line, Level.Critical, msg);
    }

    /*
     * Write message with level "fatal" to logger
     */
    void fatal(string file = __FILE__ , size_t line = __LINE__ , M...)(lazy const M msg) nothrow
    {
        putMsg(file, line, Level.Fatal, msg);
    }

    void setLevel(string level) @system
    {
        _level = level.toLevel;

        _config.level = level;
    }

    void setFilename(string filename)
    {
        _config.filename     = filename;
        _config.appenderType = "FileAppender";
    }

    void setEncoder(Encoder encoder)
    {
        _encoder = encoder;
    }

    void setRolling()
    {}

    void setMaxSize(uint maxSize)
    {
        _config.maxSize = maxSize;
    }

    void setMaxHistory(uint maxHistory)
    {
        _config.maxHistory = maxHistory;
    }
    
@system:
private:

    /* Name */
    string       _name;

    /* Config */
    LoggerConfig _config;

    /* Level */
    Level        _level;

    /* Appender */
    Appender     _appender;

    /* Encoder */
    Encoder      _encoder;

    /*
     * Level getter in string type
     */
    // public immutable (string) level()
    // {
    //     return _level.levelToString();
    // }

    /*
     * Create logger impl
     *
     * Throws: LogCreateException, ConfException
     */
    this()
    {
    }

    /*
     * Create logger impl
     *
     * Throws: LogCreateException, ConfException
     */
    this(string filename, string level = "trace")
    {
        _config.filename = filename;

        this.setLevel(level);
    }

    Appender appender()
    {
        if (_appender is null)
        {
            _appender = createAppender(_config);
        }

        return _appender;
    }

    Encoder encoder()
    {
        if (_encoder is null)
        {
            _encoder = new DefaultEncoder;
        }

        return _encoder;
    }

    /*
     * Extract logger type from bundle
     *
     * Throws: BundleException, LogCreateException
     */
    @trusted /* Object.factory is system */
    Appender createAppender(LoggerConfig config)
    {
        AppenderFactory f = cast(AppenderFactory)Object.factory("geario.logging.appender." ~ config.appenderType ~ "Factory");

        if (f is null)
        {
            throw new  LoggerCreateException("Error create log appender: " ~ config.appenderType  ~ "  is Illegal appender type.");
        }

        return f.factory(config);
    }

    /*
     * Encode message and put to appender
     */
    @trusted
    void putMsg(M...)(string file, size_t line, Level level, lazy M msg) nothrow
    {
        if (level >= _level)
        {
            string emsg;

            try
            {
                import std.format;
                import std.conv : to;

                auto fmsg = format(msg[0].to!string, msg[1 .. $]);
                emsg = encoder().encode(file, line, level, fmsg);
            }
            catch (Exception e)
            {
                try
                {
                    emsg = encoder().encode(file, line, Level.Error, "Error in encoding log message: " ~ e.msg);
                }
                catch (Exception ee)
                {
                    fixException(ee);
                    return;
                }
            }

            try
            {
                appender.append(level, emsg);
            }
            catch (Exception e)
            {
                fixException(e);
            }
        }
    }

    /**
     * Logger exeption handler
     */
    @trusted
    void fixException (Exception e) nothrow
    {
        try
        {
            synchronized(lock)
            {
                errorFile.writeln("Error to work with log Exception-> "  ~ e.msg);
            }
        }
        catch(Exception e){}
    }
}

@system:
private:


import core.sync.mutex;
import std.stdio;
import geario.logging.appender;

/* Mutex use for block work with loggers pool */
__gshared Mutex lock;
/* Save loggers by names in pool */
__gshared Logger[immutable string] _loggers;
/* Save loggers errors in file */
__gshared File errorFile;
/* Global logger object */
__gshared Logger  _defaultGlobalLogger;

shared static this()
{
    lock = new Mutex();
}

interface Encoder
{
    string encode (string file, size_t line, immutable Level level, const string message);
}

class DefaultEncoder : Encoder
{
    import std.datetime;

    /**
     * Do make message finish string
     *
     * Throws: Exception
     */
    string encode(string file, size_t line, immutable Level level, const string message)
    {
        import std.string : format;
        import std.conv : to;

		import geario.util.DateTime : date;
        import geario.util.ThreadHelper : GetTid;
        
        string strLevel = "[" ~ levelToViewString(level) ~ "]";
        return format("%-19s %s %-7s %s - %s:%d", date("Y-m-d H:i:s", Clock.currTime.toUnixTime()), GetTid().to!string, strLevel, message, file, line);
    }
}
