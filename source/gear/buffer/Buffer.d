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

module gear.buffer.Buffer;

import gear.Exceptions;

import std.conv;
import std.format;
import std.stdio;
import std.algorithm;
import std.string;
import nbuff;
import gear.buffer.Bytes;


/** 
 * 
 */
struct Buffer
{

    private Nbuff _nbuff;

    this(int value)
    {
        Append(value);
    }

    this(long value)
    {
        Append(value);
    }

    this(string str)
    {
        Append(str);
    }

    this(byte[] array)
    {
        AppendBytes(array);
    }

    this(const ubyte[] array)
    {
        AppendBytes(array);
    }

    /**
     * clear this buffer.
     *
     * @return 
     */
    void Clear() @nogc @safe
    {
        _nbuff.clear();
    }

    static auto Get(size_t size) @safe @nogc
    {
        // take memory from pool
        return MutableNbuffChunk(size);
    }

    /**
     * make the buffer to string.
     *
     * @return  string
     */
    string toString() @safe
    {
        return _nbuff.toString();
    }

    /**
     * Returns this buffer is empty.
     *
     * @return  bool
     */
    bool Empty() pure inout nothrow @safe @nogc
    {
        return _nbuff.empty();
    }

    /**
     * Returns this buffer's Dump.
     *
     * @return  string
     */
    string Dump() @safe
    {
        return _nbuff.dump();
    }

    /**
     * Get buffer's length.
     *
     * @return  size_t
     */
    size_t Length() pure nothrow @nogc @safe inout
    {
        return _nbuff.length();
    }

    /**
     * the buffer put string.
     *
     * @return  void
     */
    void Append(string str) @safe @nogc
    {
        _nbuff.append(str);
    }

    /**
     * the buffer put string.
     *
     * @return  void
     */
    void Append(Bytes bytes)
    {
        auto chunk = NbuffChunk(cast(string)bytes.Chunk());
        _nbuff.append(chunk);
    }

    /**
     * the buffer put int.
     *
     * @return 
     */
    void Append(T)(T tInt)
    {
        static if(is(T == NbuffChunk)) {
            _nbuff.append(tInt);
        } else {
            NbuffChunk chunk =  NbuffChunk((cast(immutable(ubyte)[])[tInt]));
            _nbuff.append(chunk);
        }
    }

    /**
     * the buffer put byte[].
     *
     * @return 
     */
    void AppendBytes(T)(T tByte)
    {
        NbuffChunk chunk =  NbuffChunk((cast(immutable(ubyte)[])tByte));
        _nbuff.append(chunk);
    }

    /**
     * the buffer put MutableMemoryChunk.
     *
     * @return
     */
    void Append(ref UniquePtr!(MutableMemoryChunk) chunk, size_t size) @safe @nogc
    {
        _nbuff.append(chunk, size);
    }

    /**
     * the buffer put NbuffChunk.
     *
     * @return
     */
    void Append(ref NbuffChunk source) @safe @nogc
    {
        _nbuff.append(source);
    }

    /**
     * the buffer put NbuffChunk of pos and len. 
     *
     * @return
     */
    void Append(ref NbuffChunk source, size_t pos, size_t len) @safe @nogc
    {
        _nbuff.append(source, pos, len);
    }

    /**
     * looking front chunk from Nbuff 
     *
     * @return chunk
     */
    auto FrontChunk() @safe @nogc
    {
        return _nbuff.frontChunk();
    }

    /**
     * pop chunk from Nbuff 
     *
     * @return chunk
     */
    void PopChunk() @safe @nogc
    {
        _nbuff.popChunk();
    }

    /**
     * pop chunk from Nbuff 
     *
     * @return
     */
    void Pop(long iVal=1) @safe @nogc
    {
        _nbuff.pop(iVal);
    }

    /**
     * 
     *
     * @return NbuffChunk
     */
    NbuffChunk Data(size_t beg, size_t end) @safe
    {
        return _nbuff.data(beg, end);
    }
    
    /**
     * 
     *
     * @return NbuffChunk
     */
    NbuffChunk Data() @safe @nogc
    {
        return _nbuff.data();
    }

    ///
    /// copy references to RC-data
    ///
    void opAssign(Buffer other) @safe @nogc
    {
        _nbuff.opAssign(other._nbuff);
    }

    /**
     * 
     *
     * @return Nbuff
     */
    Nbuff opSlice(size_t start, size_t end) @nogc @safe
    {
        return _nbuff.opSlice(start, end);
    }

    /**
     * 
     *
     * @return chunk
     */
    auto opDollar()
    {
        return _nbuff.opDollar();
    }

    /**
     * 
     *
     * @return bool
     */
    bool opEquals(string str) pure const @safe @nogc
    {
        return _nbuff.opEquals(str);
    }

    /**
     * 
     *
     * @return bool
     */
    bool opEquals(const ubyte[] ubytes) pure const @safe @nogc
    {
        return _nbuff.opEquals(ubytes);
    }

    /**
     * 
     *
     * @return bool
     */
    bool opEquals(this R)(auto ref R other) pure @safe @nogc
    {
        //return _nbuff.opEquals(other);
        return false;
    }

    /**
     * 
     *
     * @return chunk
     */
    auto opIndex(size_t size) @safe @nogc inout
    {
        return _nbuff.opIndex(size);
    }

    /**
     * 
     *
     * @return Nbuff
     */
    Nbuff[3] FindSplitOn(string str, size_t start_from = 0) @safe @nogc
    {
        return _nbuff.findSplitOn(str.representation, start_from);
    }

    /**
     * 
     *
     * @return Nbuff
     */
    Nbuff[3] FindSplitOn(immutable(ubyte)[] ubytes, size_t start_from = 0) @safe @nogc
    {
        return _nbuff.findSplitOn(ubytes, start_from);
    }

    /**
     * 
     *
     * @return bool
     */
    bool BeginsWith(const ubyte[] ubytes) @safe @nogc
    {
        return _nbuff.beginsWith(ubytes);
    }

    /**
     * 
     *
     * @return bool
     */
    bool BeginsWith(string str) @safe @nogc
    {
        return _nbuff.beginsWith(str);
    }

    /**
     * 
     *
     * @return int
     */
    int countUntil(const(ubyte)[] ubytes, size_t start_from = 0) pure inout @safe @nogc
    {
        return _nbuff.countUntil(ubytes, start_from);
    }
}