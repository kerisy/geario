module geario.util.ConverterUtils;

import geario.Exceptions;
import geario.util.Appendable;
import geario.util.StringBuilder;
import geario.util.Traits;

import std.conv;
import std.format;
import std.string;
import std.typecons;
import std.ascii;

/**
 * 
 */
struct ConverterUtils {

    /**
     * @param c An ASCII encoded character 0-9 a-f A-F
     * @return The byte value of the character 0-16.
     */
    static byte ConvertHexDigit(byte c) {
        byte b = cast(byte)((c & 0x1f) + ((c >> 6) * 0x19) - 0x10);
        if (b < 0 || b > 15)
            throw new NumberFormatException("!hex " ~ to!string(c));
        return b;
    }

    /* ------------------------------------------------------------ */

    /**
     * @param c An ASCII encoded character 0-9 a-f A-F
     * @return The byte value of the character 0-16.
     */
    static int ConvertHexDigit(char c) {
        int d = ((c & 0x1f) + ((c >> 6) * 0x19) - 0x10);
        if (d < 0 || d > 15)
            throw new NumberFormatException("!hex " ~ to!string(c));
        return d;
    }

    /* ------------------------------------------------------------ */

    /**
     * @param c An ASCII encoded character 0-9 a-f A-F
     * @return The byte value of the character 0-16.
     */
    static int ConvertHexDigit(int c) {
        int d = ((c & 0x1f) + ((c >> 6) * 0x19) - 0x10);
        if (d < 0 || d > 15)
            throw new NumberFormatException("!hex " ~ to!string(c));
        return d;
    }

    /* ------------------------------------------------------------ */
    static void ToHex(byte b, Appendable buf) {
        try {
            int d = 0xf & ((0xF0 & b) >> 4);
            buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
            d = 0xf & b;
            buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        }
        catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    /* ------------------------------------------------------------ */
    static void ToHex(int value, Appendable buf) {
        int d = 0xf & ((0xF0000000 & value) >> 28);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & ((0x0F000000 & value) >> 24);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & ((0x00F00000 & value) >> 20);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & ((0x000F0000 & value) >> 16);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & ((0x0000F000 & value) >> 12);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & ((0x00000F00 & value) >> 8);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & ((0x000000F0 & value) >> 4);
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));
        d = 0xf & value;
        buf.Append(cast(char)((d > 9 ? ('A' - 10) : '0') + d));

        // Integer.toString(0, 36);
    }

    /* ------------------------------------------------------------ */
    static void ToHex(long value, Appendable buf) {
        ToHex(cast(int)(value >> 32), buf);
        ToHex(cast(int) value, buf);
    }

    /* ------------------------------------------------------------ */
    static string ToHexString(byte b) {
        return ToHexString([b], 0, 1);
    }

    /* ------------------------------------------------------------ */
    static string ToHexString(byte[] b) {
        return ToHexString(b, 0, cast(int) b.length);
    }

    /* ------------------------------------------------------------ */
    static string ToHexString(byte[] b, int offset, int length) {
        StringBuilder buf = new StringBuilder();
        for (int i = offset; i < offset + length; i++) {
            int bi = 0xff & b[i];
            int c = '0' + (bi / 16) % 16;
            if (c > '9')
                c = 'A' + (c - '0' - 10);
            buf.Append(cast(char) c);
            c = '0' + bi % 16;
            if (c > '9')
                c = 'a' + (c - '0' - 10);
            buf.Append(cast(char) c);
        }
        return buf.toString();
    }

    static string ToHexString(LetterCase letterCase = LetterCase.upper)(const(ubyte)[] b, 
            string separator="", string prefix="") {
        static if(letterCase == LetterCase.upper) {
            string fmt = "%(" ~ prefix ~ "%02X" ~ separator ~ "%)";
        } else {
            string fmt = "%(" ~ prefix ~ "%02x" ~ separator ~ "%)";
        }

        return format(fmt, b);
    }

    /* ------------------------------------------------------------ */
    /**
    */
    static T[] ToBytes(T)(string s) if(isByteType!T) {
        if (s.length % 2 != 0)
            throw new IllegalArgumentException(s);
        T[] r = new T[s.length/2];
        for(size_t i=0; i<r.length; i++) {
            size_t j = i+i;
            r[i] = cast(T)to!(int)(s[j .. j+2], 16);
        }
        return r;
    }

    /**
    */
    static byte[] FromHexString(string s) {
        return ToBytes!byte(s);
        // if (s.length % 2 != 0)
        //     throw new IllegalArgumentException(s);
        // byte[] array = new byte[s.length / 2];
        // for (int i = 0; i < array.length; i++) {
        //     int b = to!int(s[i * 2 .. i * 2 + 2], 16);
        //     array[i] = cast(byte)(0xff & b);
        // }
        // return array;
    }

    static int ParseInt(string s, int offset, int length, int base) {
        return to!int(s[offset .. offset + length], base);
    }

}