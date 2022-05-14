module geario.system.WindowsHelper;

// dfmt off
version (Windows):
// dfmt on

import std.exception;
import std.stdio;
import std.windows.charset;

import core.sys.windows.wincon;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.stdc.stdio;

struct ConsoleHelper {
    private __gshared HANDLE g_hout;
    enum defaultColor = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE;

    shared static this() {
        g_hout = GetStdHandle(STD_OUTPUT_HANDLE);
        ResetColor();
    }

    static HANDLE GetHandle() nothrow {
        return g_hout;
    }

    static void ResetColor() nothrow {
        SetConsoleTextAttribute(g_hout, defaultColor);
    }

    static void SetTextAttribute(ushort attr) nothrow {
        SetConsoleTextAttribute(g_hout, attr);
    }

    static void Write(lazy string msg) nothrow {
        try {
            printf("%s\n", toMBSz(msg));
        } catch(Exception ex) {
            collectException( {
                SetTextAttribute(FOREGROUND_RED);
                writeln(ex); 
                SetTextAttribute(defaultColor);
            }());
        }
    }

    static void writeWithAttribute(lazy string msg, ushort attr = defaultColor) nothrow {
        SetTextAttribute(attr);
        try {
            printf("%s\n", toMBSz(msg));
            if ((attr & defaultColor) != defaultColor)
                ResetColor();
        } catch(Exception ex) {
            collectException( {
                SetTextAttribute(FOREGROUND_RED);
                writeln(ex); 
                SetTextAttribute(defaultColor);
            }());
        }
    }
}

