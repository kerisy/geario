module gear.serialization.BinarySerialization;

import gear.serialization.BinarySerializer;
import gear.serialization.BinaryDeserializer;
import gear.serialization.Common;

import std.traits;

ubyte[] Serialize(SerializationOptions options = SerializationOptions.Full, T)(T obj) {
    auto serializer = BinarySerializer();
    return serializer.oArchive!(options)(obj);
}

T Unserialize(T, SerializationOptions options = SerializationOptions.Full)(ubyte[] buffer) {
    auto deserializer = BinaryDeserializer(buffer);
    return deserializer.iArchive!(options, T);
}


alias toObject = Unserialize;
alias toBinary = Serialize;