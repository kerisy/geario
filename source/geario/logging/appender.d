module geario.logging.appender;

@system:
package:

import geario.logging.config;

/**
 * Appender Creating interface
 *
 * Use by Logger for create new Appender
 *
 * ====================================================================================
 */
interface AppenderFactory
{
    Appender factory(LoggerConfig config);
}


/**
 * Accept messages and publicate it in target
 */
abstract class Appender
{
    /**
     * Append new message
     */
    void append(Level level, string message);
}


/**
 * Factory for NullAppender
 *
 * ====================================================================================
 */
class NullAppenderFactory:AppenderFactory
{
    override Appender factory(LoggerConfig config)
    {
        return new NullAppender();
    }
}


/**
 * Only Accept messages
 */
class NullAppender:Appender
{
    /**
     * Append new message and do nothing
     */
    override void append(Level level, string message) nothrow pure {}
}


/**
 * Factory for ConsoleAppender
 *
 * ====================================================================================
 */
class ConsoleAppenderFactory:AppenderFactory
{
    override Appender factory(LoggerConfig config)
    {
        return new ConsoleAppender();
    }
}


/**
 * Accept messages and publicate it on console
 */
class ConsoleAppender:Appender
{
    /**
     * Append new message and print it to console
     */
    @trusted /* writefln is system */
    override void append(Level level, string message)
    {
        import colorize : fg, color, cwriteln, cwritefln;

        fg c;

        switch (level)
        {
            case level.Warning:
                c = fg.yellow;
                break;
            case Level.Error:
            case Level.Fatal:
                c = fg.red;
                break;
            case Level.Info:
                c = fg.green;
                break;
            default:
                c = fg.init;
        }

        cwriteln(message.color(c));
    }
}


/**
 * Factory for FileAppender
 *
 * ====================================================================================
 */
class FileAppenderFactory:AppenderFactory
{
    override Appender factory(LoggerConfig config)
    {
        return new FileAppender(config);
    }
}


/**
 * Accept messages and publicate it in file
 */
class FileAppender:Appender
{
    import std.concurrency;

    /* Tid for appender activity */
    Tid activity;

    /**
     * Create Appender
     */
    @trusted
    this(LoggerConfig config)
    {
        activity = spawn(&fileAppenderActivityStart, config);
    }

    /**
     * Append new message and send it to file
     */
    @trusted
    override void append(Level level, string message)
    {
        activity.send(message);
    }
}


/**
 * Start new thread for file log activity
 */
@system
void fileAppenderActivityStart(LoggerConfig config) nothrow
{
    try
    {
        new FileAppenderActivity(config).run();
    }
    catch (Exception e)
    {
        try
        {
            import std.stdio;
            writeln("FileAppenderActivity exception: " ~ e.msg);
        }
        catch (Exception ioe){}
    }
}


/**
 * Logger FileAppender activity
 *
 * Write log message to file from one thread
 */
class FileAppenderActivity
{
    import geario.logging.storage;
    import std.concurrency;
    import std.datetime;

    /* Max flush period to write to file */
    enum logFileWriteFlushPeriod = 100; // ms

    /* Activity working status */
    enum AppenderWorkStatus {WORKING, STOPPING}
    private auto workStatus = AppenderWorkStatus.WORKING;

    long startFlushTime;

    /* Max flush period to write to file */
    FileStorage storage;

    /**
     * Primary constructor
     *
     * Save config path and name
     */
    this(LoggerConfig config)
    {
        storage = FileStorage(config);
        startFlushTime = Clock.currStdTime();
    }

    /**
     * Entry point for start module work
     */
    @system
    void run()
    {
        /**
         * Main activity cycle
         */
        while (workStatus == AppenderWorkStatus.WORKING)
        {
            try
            {
                workCycle();
            }
            catch (Exception e)
            {
                import std.stdio;
                writeln("FileAppenderActivity workcycle exception: " ~ e.msg);
            }
        }
    }

    /**
     * Activity main cycle
     */
    @trusted
    private void workCycle()
    {
        receiveTimeout(
            100.msecs,
            (string msg)
            {
                storage.saveMsg(msg);
            },
            (OwnerTerminated e){workStatus = AppenderWorkStatus.STOPPING;},
            (Variant any){}
        );

        if (logFileWriteFlushPeriod <= (Clock.currStdTime() - startFlushTime)/(1000*10))
        {
            storage.flush;
            startFlushTime = Clock.currStdTime();
        }
    }
}
