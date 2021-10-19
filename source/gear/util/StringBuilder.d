/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.util.StringBuilder;

import gear.util.Appendable;

import std.ascii;
import std.algorithm;
import std.array;
import std.exception;
import std.conv;
import std.string;
import std.uni;

/**
 * 
 */
class StringBuilder : Appendable {
    Appender!(byte[]) _buffer;

    this(size_t capacity = 16) {
        _buffer.reserve(capacity);
    }

    this(string data, size_t capacity = 16) {
        _buffer.reserve(capacity);
        this.Append(data);
    }

    // void Append(in char[] s)
    // {
    //     _buffer.put(cast(string) s);
    // }

    void Reset() {
        _buffer.clear();
    }

    StringBuilder SetCharAt(int index, char c) {
        _buffer.data[index] = c;
        return this;
    }

    StringBuilder Append(char s) {
        _buffer.put(s);
        return this;
    }

    StringBuilder Append(bool s) {
        Append(s.to!string());
        return this;
    }

    StringBuilder Append(int i) {
        _buffer.put(cast(byte[])(to!(string)(i)));
        return this;
    }

    StringBuilder Append(float f) {
        _buffer.put(cast(byte[])(to!(string)(f)));
        return this;
    }

    StringBuilder Append(const(char)[] s) {
        _buffer.put(cast(byte[]) s);
        return this;
    }

    StringBuilder Append(const(char)[] s, int start, int end) {
        _buffer.put(cast(byte[]) s[start .. end]);
        return this;
    }

    // StringBuilder Append(byte[] s, int start, int end)
    // {
    //     _buffer.put(s[start..end]);
    //     return this;
    // }

    /// Warning: It's different from the previous one.
    StringBuilder Append(byte[] str, int offset, int len) {
        _buffer.put(str[offset .. offset + len]);
        return this;
    }

    StringBuilder Append(Object obj) {
        _buffer.put(cast(byte[])(obj.toString));
        return this;
    }

    int Length() {
        return cast(int) _buffer.data.length;
    }

    void SetLength(int newLength) {
        _buffer.shrinkTo(newLength);
        // if (newLength < 0)
        //     throw new StringIndexOutOfBoundsException(to!string(newLength));
        // EnsureCapacityInternal(newLength);

        // if (count < newLength) {
        //     Arrays.fill(value, count, newLength, '\0');
        // }

        // count = newLength;
    }

    private void EnsureCapacityInternal(size_t minimumCapacity) {
        // overflow-conscious code
        // if (minimumCapacity > value.length) {
        //     value = Arrays.copyOf(value,
        //             newCapacity(minimumCapacity));
        // }
    }

    int LastIndexOf(string s) {
        string source = cast(string) _buffer.data;
        return cast(int) source.lastIndexOf(s);
    }

    char CharAt(int idx) {
        if (Length() > idx)
            return _buffer.data[idx];
        else
            return ' ';
    }

    StringBuilder DeleteCharAt(int index) {
        if (index < Length()) {
            auto data = _buffer.data.idup;
            for (int i = index + 1; i < data.length; i++) {
                _buffer.data[i - 1] = data[i];
            }
            SetLength(cast(int)(data.length - 1));
        }
        return this;
    }

    StringBuilder Insert(int index, char c) {
        if (index <= Length()) {
            auto data = _buffer.data.idup;
            for (int i = index; i < data.length; i++) {
                _buffer.data[i + 1] = data[i];
            }
            _buffer.data[index] = c;
            SetLength(cast(int)(data.length + 1));
        }
        return this;
    }

    StringBuilder Insert(int index, long data) {
        auto bytes = cast(byte[])(to!string(data));
        auto start = index;
        foreach (b; bytes) {
            Insert(start, cast(char) b);
            start++;
        }
        return this;
    }

    StringBuilder Replace(int start, int end, string str) {
        if (start <= end && start < Length() && end < Length()) {
            if (str.length >= end)
                _buffer.data[start .. end] = cast(byte[])(str[start .. end]);
        }
        return this;
    }

    void Clear() {
        _buffer = Appender!(byte[]).init;
    }

    override string toString() {
        string s = cast(string) _buffer.data.idup;
        if (s is null)
            return "";
        else
            return s;
    }
}
