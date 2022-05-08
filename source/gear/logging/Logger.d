/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module gear.logging.Logger;

// import gear.util.ThreadHelper;

import gear.util.ThreadHelper;

import core.thread;

import std.algorithm.iteration;
import std.array;
import std.concurrency;
import std.exception;
import std.file;
import std.parallelism;
import std.stdio;
import std.datetime;
import std.format;
import std.range;
import std.conv;
import std.regex;
import std.path;
import std.typecons;
import std.traits;
import std.string;



private:

class SizeBaseRollover
{

    import std.path;
    import std.string;
    import std.typecons;

    string path;
    string dir;
    string baseName;
    string ext;
    string activeFilePath;

    /**
     * Max size of one file
     */
    uint maxSize;

    /**
     * Max number of working files
     */
    uint maxHistory;

    this(string fileName, string size, uint maxNum)
    {
        path = fileName;
        auto fileInfo = ParseConfigFilePath(fileName);
        dir = fileInfo[0];
        baseName = fileInfo[1];
        ext = fileInfo[2];

        activeFilePath = path;
        maxSize = ExtractSize(size);

        maxHistory = maxNum;
    }

    auto ParseConfigFilePath(string rawConfigFile)
    {
        string configFile = buildNormalizedPath(rawConfigFile);

        immutable dir = configFile.dirName;
        string fullBaseName = std.path.baseName(configFile);
        auto ldotPos = fullBaseName.lastIndexOf(".");
        immutable ext = (ldotPos > 0) ? fullBaseName[ldotPos + 1 .. $] : "log";
        immutable baseName = (ldotPos > 0) ? fullBaseName[0 .. ldotPos] : fullBaseName;

        return tuple(dir, baseName, ext);
    }

    uint ExtractSize(string size)
    {
        import std.uni : toLower;
        import std.uni : toUpper;
        import std.conv;

        uint nsize = 0;
        auto n = matchAll(size, regex(`\d*`));
        if (!n.empty && (n.hit.length != 0))
        {
            nsize = to!int(n.hit);
            auto m = matchAll(size, regex(`\D{1}`));
            if (!m.empty && (m.hit.length != 0))
            {
                switch (m.hit.toUpper)
                {
                case "K":
                    nsize *= KB;
                    break;
                case "M":
                    nsize *= MB;
                    break;
                case "G":
                    nsize *= GB;
                    break;
                case "T":
                    nsize *= TB;
                    break;
                case "P":
                    nsize *= PB;
                    break;
                default:
                    throw new Exception("In Logger configuration uncorrect number: " ~ size);
                }
            }
        }
        return nsize;
    }

    enum KB = 1024;
    enum MB = KB * 1024;
    enum GB = MB * 1024;
    enum TB = GB * 1024;
    enum PB = TB * 1024;

    /**
     * Scan work directory
     * save needed files to pool
      */
    string[] ScanDir()
    {
        import std.algorithm.sorting : sort;
        import std.algorithm;

        bool tc(string s)
        {
            static import std.path;

            auto base = std.path.baseName(s);
            auto m = matchAll(base, regex(baseName ~ `\d*\.` ~ ext));
            if (m.empty || (m.hit != base))
            {
                return false;
            }
            return true;
        }

        return std.file.dirEntries(dir, SpanMode.shallow)
            .filter!(a => a.isFile).map!(a => a.name).filter!(a => tc(a))
            .array.sort!("a < b").array;
    }

    /**
     * Do files rolling by size
     */

    bool Roll(string msg)
    {
        auto filePool = ScanDir();
        if (filePool.length == 0)
        {
            return false;
        }
        if ((getSize(filePool[0]) + msg.length) >= maxSize)
        {
            //if ((filePool.front.getSize == 0) throw
            if (filePool.length >= maxHistory)
            {
                std.file.remove(filePool[$ - 1]);
                filePool = filePool[0 .. $ - 1];
            }
            //carry(filePool);
            return true;
        }
        return false;
    }

    /**
     * Rename log files
     */

    void Carry()
    {
        import std.conv;
        import std.path;

        auto filePool = ScanDir();
        foreach_reverse (ref file; filePool)
        {
            auto newFile = dir ~ dirSeparator ~ baseName ~ to!string(ExtractNum(file) + 1)
                ~ "." ~ ext;
            std.file.rename(file, newFile);
            file = newFile;
        }
    }

    /**
     * Extract number from file name
     */
    uint ExtractNum(string file)
    {
        import std.conv;

        uint num = 0;
        try
        {
            static import std.path;
            import std.string;

            auto fch = std.path.baseName(file).chompPrefix(baseName);
            auto m = matchAll(fch, regex(`\d*`));

            if (!m.empty && m.hit.length > 0)
            {
                num = to!uint(m.hit);
            }
        }
        catch (Exception e)
        {
            throw new Exception("Uncorrect log file name: " ~ file ~ "  -> " ~ e.msg);
        }
        return num;
    }

}

__gshared Logger g_logger = null;

version (Windows)
{
    import core.sys.windows.wincon;
    import core.sys.windows.winbase;
    import core.sys.windows.windef;

    private __gshared HANDLE g_hout;
    shared static this() {
        g_hout = GetStdHandle(STD_OUTPUT_HANDLE);
    }
}

/**
*/
class Logger
{

    __gshared Logger[string] g_logger;
    static Logger CreateLogger(string name , LogConf conf)
    {
        g_logger[name] = new Logger(conf);
        return g_logger[name];
    }

    static Logger getLogger(string name)
    {
        return g_logger[name];
    }

    void Log(string file = __FILE__ , size_t line = __LINE__ , string func = __FUNCTION__ , A ...)(LogLevel level , lazy A args)
    {
        Write(level , toFormat(func , LogFormat(args) , file , line , level));
    }

    void Logf(string file = __FILE__ , size_t line = __LINE__ , string func = __FUNCTION__ , A ...)(LogLevel level , lazy A args)
    {
        Write(level , toFormat(func , LogFormatf(args) , file , line , level));
    }

    this(LogConf conf)
    {
        _conf = conf;
        string fileName = conf.fileName;

        if (!fileName.empty)
        {
            if(exists(fileName) && isDir(fileName))
                throw new Exception("A direction has existed with the same name.");
            
            CreatePath(conf.fileName);
            _file = File(conf.fileName, "a");
            _rollover = new SizeBaseRollover(conf.fileName, _conf.maxSize, _conf.maxNum);
        }

        immutable void* data = cast(immutable void*) this;
        if(!_conf.fileName.empty)
            _tid = spawn(&Logger.worker, data);
    }

    void Write(LogLevel level, string msg)
    {
        if (level >= _conf.level)
        {
            //#1 console 
            //check if enableConsole or appender == AppenderConsole

            if (_conf.fileName == "" || !_conf.disableConsole)
            {
                WriteFormatColor(level, msg);
            }

            //#2 file
            if (_conf.fileName != "")
            {
                send(_tid, msg);
            }
        }
    }



protected:

    static void worker(immutable void* ptr)
    {
        Logger logger = cast(Logger) ptr;
        bool flag = true;
        while (flag)
        {
            receive((string msg) {
                logger.SaveMsg(msg);
            }, (OwnerTerminated e) { flag = false; }, (Variant any) {  });
        }
    }

    void SaveMsg(string msg)
    {
        try
        {

            if (!_file.name.exists)
            {
                _file = File(_rollover.activeFilePath, "w");
            }
            else if (_rollover.Roll(msg))
            {
                _file.detach();
                _rollover.Carry();
                _file = File(_rollover.activeFilePath, "w");
            }
            else if (!_file.isOpen())
            {
                _file.open("a");
            }
            _file.writeln(msg);
            _file.flush();

        }
        catch (Throwable e)
        {
            writeln(e.toString());
        }

    }

    static void CreatePath(string fileFullName)
    {
        import std.path : dirName;
        import std.file : mkdirRecurse;
        import std.file : exists;

        string dir = dirName(fileFullName);
        if (!exists(dir))
            mkdirRecurse(dir);
    }

    static string toString(LogLevel level)
    {
        string l;
        final switch (level) with (LogLevel)
        {
        case LOG_DEBUG:
            l = "debug";
            break;
        case LOG_INFO:
            l = "Info";
            break;
        case LOG_WARNING:
            l = "Warning";
            break;
        case LOG_ERROR:
            l = "Error";
            break;
        case LOG_FATAL:
            l = "Fatal";
            break;
        case LOG_Off:
            l = "off";
            break;
        }
        return l;
    }

    static string LogFormatf(A...)(A args)
    {
        auto strings = appender!string();
        formattedWrite(strings, args);
        return strings.data;
    }

    static string LogFormat(A...)(A args)
    {
        auto w = appender!string();
        foreach (arg; args)
        {
            alias A = typeof(arg);
            static if (isAggregateType!A || is(A == enum))
            {
                import std.format : formattedWrite;

                formattedWrite(w, "%s", arg);
            }
            else static if (isSomeString!A)
            {
                put(w, arg);
            }
            else static if (isIntegral!A)
            {
                import std.conv : toTextRange;

                toTextRange(arg, w);
            }
            else static if (isBoolean!A)
            {
                put(w, arg ? "true" : "false");
            }
            else static if (isSomeChar!A)
            {
                put(w, arg);
            }
            else
            {
                import std.format : formattedWrite;

                // Most general case
                formattedWrite(w, "%s", arg);
            }
        }
        return w.data;
    }

    static string toFormat(string func, string msg, string file, size_t line, LogLevel level)
    {
        import gear.util.DateTime;
        string time_prior = Date("Y-m-d H:i:s");

        string tid = to!string(GetTid());

        string[] funcs = func.split(".");
        string myFunc;
        if (funcs.length > 0)
            myFunc = funcs[$ - 1];
        else
            myFunc = func;

        return time_prior ~ " (" ~ tid ~ ") [" ~ toString(
                level) ~ "] " ~ myFunc ~ " - " ~ msg ~ " - " ~ file ~ ":" ~ to!string(line);
    }

protected:

    LogConf _conf;
    Tid _tid;
    File _file;
    SizeBaseRollover _rollover;
    version (Posix)
    {
        enum PRINT_COLOR_NONE = "\033[m";
        enum PRINT_COLOR_RED = "\033[0;32;31m";
        enum PRINT_COLOR_GREEN = "\033[0;32;32m";
        enum PRINT_COLOR_YELLOW = "\033[1;33m";
    }

    static void WriteFormatColor(LogLevel level, string msg)
    {
        version (Posix)
        {
            string prior_color;
            switch (level) with (LogLevel)
            {
                case LOG_ERROR:
                case LOG_FATAL:
                    prior_color = PRINT_COLOR_RED;
                    break;
                case LOG_WARNING:
                    prior_color = PRINT_COLOR_YELLOW;
                    break;
                case LOG_INFO:
                    prior_color = PRINT_COLOR_GREEN;
                    break;
                default:
                    prior_color = string.init;
            }

            writeln(prior_color ~ msg ~ PRINT_COLOR_NONE);
        }
        else version (Windows)
        {
            import std.windows.charset;
            import core.stdc.stdio;

            enum defaultColor = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE;

            ushort color;
            switch (level) with (LogLevel)
            {
            case LOG_ERROR:
            case LOG_FATAL:
                color = FOREGROUND_RED;
                break;
            case LOG_WARNING:
                color = FOREGROUND_GREEN | FOREGROUND_RED;
                break;
            case LOG_INFO:
                color = FOREGROUND_GREEN;
                break;
            default:
                color = defaultColor;
            }

            SetConsoleTextAttribute(g_hout, color);
            printf("%s\n", toMBSz(msg));
            if(color != defaultColor)
                SetConsoleTextAttribute(g_hout, defaultColor);
        }
    }
}

string code(string func, LogLevel level, bool f = false)()
{
    return "void " ~ func
        ~ `(string file = __FILE__ , size_t line = __LINE__ , string func = __FUNCTION__ , A ...)(lazy A args)
    {
        if(g_logger is null)
            Logger.WriteFormatColor(`
        ~ level.stringof ~ ` , Logger.toFormat(func , Logger.LogFormat` ~ (f
                ? "f" : "") ~ `(args) , file , line , ` ~ level.stringof ~ `));
        else
            g_logger.Write(`
        ~ level.stringof ~ ` , Logger.toFormat(func , Logger.LogFormat` ~ (f
                ? "f" : "") ~ `(args) , file , line ,` ~ level.stringof ~ ` ));
    }`;
}



public:

enum LogLevel
{
    LOG_DEBUG = 0,
    LOG_INFO = 1,    
    LOG_WARNING = 2,
    LOG_ERROR = 3,
    LOG_FATAL = 4,
    LOG_Off = 5
}

struct LogConf
{
    LogLevel level; // 0 debug 1 Info 2 Warning 3 Error 4 Fatal
    bool disableConsole;
    string fileName = "";
    string maxSize = "2MB";
    uint maxNum = 5;
}

void logLoadConf(LogConf conf)
{
    g_logger = new Logger(conf);    
}

mixin(code!("LogDebug", LogLevel.LOG_DEBUG));
mixin(code!("LogDebugf", LogLevel.LOG_DEBUG, true));
mixin(code!("LogInfo", LogLevel.LOG_INFO));
mixin(code!("LogInfof", LogLevel.LOG_INFO, true));
mixin(code!("LogWarning", LogLevel.LOG_WARNING));
mixin(code!("LogWarningf", LogLevel.LOG_WARNING, true));
mixin(code!("LogError", LogLevel.LOG_ERROR));
mixin(code!("LogErrorf", LogLevel.LOG_ERROR, true));
mixin(code!("LogFatal", LogLevel.LOG_FATAL));
mixin(code!("LogFatalf", LogLevel.LOG_FATAL, true));

alias Trace = LogDebug;
alias Tracef = LogDebugf;
alias Info = LogInfo;
alias Infof = LogInfof;
alias Warning = LogWarning;
alias Warningf = LogWarningf;
alias error = LogError;
alias errorf = LogErrorf;
alias Critical = LogFatal;
alias criticalf = LogFatalf;



