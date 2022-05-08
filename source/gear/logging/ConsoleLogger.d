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

module gear.logging.ConsoleLogger;

// import gear.util.ThreadHelper;
import gear.util.ThreadHelper;

import core.stdc.stdlib;
import core.runtime;
import core.thread;

import std.conv;
import std.datetime;
import std.exception;
import std.format;
import std.range;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;
import std.traits;

// ThreadID GetTid()
// {
//     return Thread.getThis.id;
// }

version (Windows) {
    import core.sys.windows.wincon;
    import core.sys.windows.winbase;
    import core.sys.windows.windef;
    import gear.system.WindowsHelper;

}

version (Posix) {
    enum PRINT_COLOR_NONE = "\033[m";
    enum PRINT_COLOR_RED = "\033[0;32;31m";
    enum PRINT_COLOR_GREEN = "\033[0;32;32m";
    enum PRINT_COLOR_YELLOW = "\033[1;33m";
}

version (Android) {
    import core.stdc.stdarg : va_end, va_list, va_start;
    import core.sys.posix.sys.types;

    enum {
        AASSET_MODE_UNKNOWN,
        AASSET_MODE_RANDOM,
        AASSET_MODE_STREAMING,
        AASSET_MODE_BUFFER
    }

    enum android_LogPriority {
        ANDROID_LOG_UNKNOWN,
        ANDROID_LOG_DEFAULT,
        ANDROID_LOG_VERBOSE,
        ANDROID_LOG_DEBUG,
        ANDROID_LOG_INFO,
        ANDROID_LOG_WARN,
        ANDROID_LOG_ERROR,
        ANDROID_LOG_FATAL,
        ANDROID_LOG_SILENT
    }

    enum LOG_TAG = "GEAR";

    // dfmt off
    extern (C):
    @system:
    nothrow:
    @nogc:
    // dfmt on

    struct AAssetManager;
    struct AAssetDir;
    struct AAsset;

    AAssetDir* AAssetManager_openDir(AAssetManager* mgr, const(char)* dirName);
    AAsset* AAssetManager_open(AAssetManager* mgr, const(char)* filename, int mode);
    const(char)* AAssetDir_getNextFileName(AAssetDir* assetDir);
    void AAssetDir_rewind(AAssetDir* assetDir);
    void AAssetDir_close(AAssetDir* assetDir);
    int AAsset_read(AAsset* asset, void* buf, size_t count);
    off_t AAsset_seek(AAsset* asset, off_t offset, int whence);
    void AAsset_close(AAsset* asset);
    const(void)* AAsset_getBuffer(AAsset* asset);
    off_t AAsset_getLength(AAsset* asset);
    off_t AAsset_getRemainingLength(AAsset* asset);
    int AAsset_openFileDescriptor(AAsset* asset, off_t* outStart, off_t* outLength);
    int AAsset_isAllocated(AAsset* asset);

    int __android_log_write(int prio, const(char)* tag, const(char)* text);
    int __android_log_print(int prio, const(char)* tag, const(char)* fmt, ...);
    int __android_log_vprint(int prio, const(char)* tag, const(char)* fmt, va_list ap);
    void __android_log_assert(const(char)* cond, const(char)* tag, const(char)* fmt, ...);

}

enum LogLevel {
    Trace = 0,
    Info = 1,
    Warning = 2,
    Error = 3,
    Fatal = 4,
    Off = 5
}

class ConsoleLogger {
    private __gshared LogLevel g_logLevel = LogLevel.Trace;
    private enum traceLevel = toString(LogLevel.Trace);
    private enum infoLevel = toString(LogLevel.Info);
    private enum warningLevel = toString(LogLevel.Warning);
    private enum errorLevel = toString(LogLevel.Error);
    private enum fatalLevel = toString(LogLevel.Fatal);
    private enum offlLevel = toString(LogLevel.Off);

    static void SetLogLevel(LogLevel level) {
        g_logLevel = level;
    }

    static void Trace(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Trace, Layout!(file, line, func)(LogFormat(args), traceLevel));
    }

    static void Tracef(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Trace, Layout!(file, line, func)(LogFormatf(args), traceLevel));
    }

    static void Info(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Info, Layout!(file, line, func)(LogFormat(args), infoLevel));
    }

    static void Infof(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Info, Layout!(file, line, func)(LogFormatf(args), infoLevel));
    }

    static void Warning(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Warning, Layout!(file, line,
                func)(LogFormat(args), warningLevel));
    }

    static void Warningf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Warning, Layout!(file, line,
                func)(LogFormatf(args), warningLevel));
    }

    static void Error(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Error, Layout!(file, line, func)(LogFormat(args), errorLevel));
    }

    static void Errorf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Error, Layout!(file, line, func)(LogFormatf(args), errorLevel));
    }

    static void Fatal(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Fatal, Layout!(file, line, func)(LogFormat(args), fatalLevel));
    }

    static void Fatalf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        WriteFormatColor(LogLevel.Fatal, Layout!(file, line, func)(LogFormatf(args), fatalLevel));
    }

    private static string LogFormatf(A...)(A args) {
        Appender!string buffer;
        formattedWrite(buffer, args);
        return buffer.data;
    }

    private static string LogFormat(A...)(A args) {
        auto w = appender!string();
        foreach (arg; args) {
            alias A = typeof(arg);
            static if (isAggregateType!A || is(A == enum)) {
                import std.format : formattedWrite;

                formattedWrite(w, "%s", arg);
            } else static if (isSomeString!A) {
                put(w, arg);
            } else static if (isIntegral!A) {
                import std.conv : toTextRange;

                toTextRange(arg, w);
            } else static if (isBoolean!A) {
                put(w, arg ? "true" : "false");
            } else static if (isSomeChar!A) {
                put(w, arg);
            } else {
                import std.format : formattedWrite;

                // Most general case
                formattedWrite(w, "%s", arg);
            }
        }
        return w.data;
    }

    private static string Layout(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__)(string msg, string level) {
        enum lineNum = std.conv.to!string(line);
        string time_prior = Clock.currTime.toString();
        string tid = std.conv.to!string(cast(size_t)GetTid());

        // writeln("fullname: ",func);
        string fun = func;
        ptrdiff_t index = lastIndexOf(func, '.');
        if (index != -1) {
            if (func[index - 1] != ')') {
                ptrdiff_t idx = lastIndexOf(func, '.', index);
                if (idx != -1)
                    index = idx;
            }
            fun = func[index + 1 .. $];
        }

        return time_prior ~ " | " ~ tid ~ " | " ~ level ~ " | " ~ fun ~ " | " ~ msg
            ~ " | " ~ file ~ ":" ~ lineNum;
    }

    // private static string defaultLayout(string context, string msg, string level)
    // {
    //     string time_prior = Clock.currTime.toString();
    //     string tid = std.conv.to!string(GetTid());

    //     return time_prior ~ " | " ~ tid ~ " | " ~ level ~ context ~ msg;
    // }

    static string toString(LogLevel level) nothrow {
        string r;
        final switch (level) with (LogLevel) {
        case Trace:
            r = "Trace";
            break;
        case Info:
            r = "Info";
            break;
        case Warning:
            r = "Warning";
            break;
        case Error:
            r = "Error";
            break;
        case Fatal:
            r = "Fatal";
            break;
        case Off:
            r = "Off";
            break;
        }
        return r;
    }

    private static void WriteFormatColor(LogLevel level, lazy string msg) nothrow {
        if (level < g_logLevel)
            return;

        version (Posix) {
            version (Android) {
                string prior_color;
                android_LogPriority logPrioity = android_LogPriority.ANDROID_LOG_INFO;
                switch (level) with (LogLevel) {
                case Error:
                case Fatal:
                    prior_color = PRINT_COLOR_RED;
                    logPrioity = android_LogPriority.ANDROID_LOG_ERROR;
                    break;
                case Warning:
                    prior_color = PRINT_COLOR_YELLOW;
                    logPrioity = android_LogPriority.ANDROID_LOG_WARN;
                    break;
                case Info:
                    prior_color = PRINT_COLOR_GREEN;
                    break;
                default:
                    prior_color = string.init;
                }

                try {
                    __android_log_write(logPrioity,
                            LOG_TAG, toStringz(prior_color ~ msg ~ PRINT_COLOR_NONE));
                } catch(Exception ex) {
                    collectException( {
                        Write(PRINT_COLOR_RED); 
                        Write(ex); 
                        writeln(PRINT_COLOR_NONE); 
                    }());
                }

            } else {
                string prior_color;
                switch (level) with (LogLevel) {
                case Error:
                case Fatal:
                    prior_color = PRINT_COLOR_RED;
                    break;
                case Warning:
                    prior_color = PRINT_COLOR_YELLOW;
                    break;
                case Info:
                    prior_color = PRINT_COLOR_GREEN;
                    break;
                default:
                    prior_color = string.init;
                }
                try {
                    writeln(prior_color ~ msg ~ PRINT_COLOR_NONE);
                } catch(Exception ex) {
                    collectException( {
                        write(PRINT_COLOR_RED); 
                        write(ex); 
                        writeln(PRINT_COLOR_NONE); 
                    }());
                }
            }

        } else version (Windows) {
            enum defaultColor = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE;

            ushort color;
            switch (level) with (LogLevel) {
            case Error:
            case Fatal:
                color = FOREGROUND_RED;
                break;
            case Warning:
                color = FOREGROUND_GREEN | FOREGROUND_RED;
                break;
            case Info:
                color = FOREGROUND_GREEN;
                break;
            default:
                color = defaultColor;
            }

            ConsoleHelper.writeWithAttribute(msg, color);
        } else {
            assert(false, "Unsupported OS.");
        }
    }
}

alias Trace = ConsoleLogger.Trace;
alias Tracef = ConsoleLogger.Tracef;
alias Info = ConsoleLogger.Info;
alias Infof = ConsoleLogger.Infof;
alias Warning = ConsoleLogger.Warning;
alias Warningf = ConsoleLogger.Warningf;
alias Error = ConsoleLogger.Error;
alias Errorf = ConsoleLogger.Errorf;
// alias Critical = ConsoleLogger.Critical;
// alias criticalf = ConsoleLogger.criticalf;

// alias LogDebug = Trace;
// alias LogDebugf = Tracef;
// alias LogInfo = Info;
// alias LogInfof = Infof;
// alias LogWarning = Warning;
// alias LogWarningf = Warningf;
// alias LogError = error;
// alias LogErrorf = errorf;
