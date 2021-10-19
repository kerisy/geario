module gear.serialization.BinarySerializer;

import std.array : Appender;
import std.traits;

import gear.serialization.Common;
import gear.serialization.Specify;


/**
 * 
 */
struct BinarySerializer {
    private {
        Appender!(ubyte[]) _buffer;
    }

    ubyte[] oArchive(SerializationOptions options, T)(T val) if (!isArray!T && !isAssociativeArray!T) {
        Unqual!T copy = val;
        specify!(options)(this, copy);
        return _buffer.data();
    }

    ubyte[] oArchive(SerializationOptions options, T)(const ref T val)
            if (!isDynamicArray!T && !isAssociativeArray!T && !isAggregateType!T) {
        T copy = val;
        specify!(options)(this, copy);
        return _buffer.data();
    }

    ubyte[] oArchive(SerializationOptions options, T)(const(T)[] val) {
        auto copy = (cast(T[]) val).dup;
        specify!(options)(this, copy);
        return _buffer.data();
    }

    ubyte[] oArchive(SerializationOptions options, K, V)(const(V[K]) val) {
        auto copy = cast(V[K]) val.dup;
        specify!(options)(this, copy);
        return _buffer.data();
    }

    void PutUbyte(ref ubyte val) {
        _buffer.put(val);
    }

    void PutClass(SerializationOptions options, T)(T val) if (is(T == class)) {
        specifyClass!(options)(this, val);
    }

    void PutRaw(ubyte[] val) {
        _buffer.put(val);
    }

    bool IsNullObj() {
        return false;
    }

}
