module codec.Framed;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

import codec.Codec;

import gear.net.TcpStream;
import gear.net.channel.Types;

import gear.logging.ConsoleLogger;

alias FrameHandle(T) = void delegate(T bufer);

/** 
 * 
 */
class Framed(T)
{
    private TcpStream _connection;
    private Codec _codec;
    private FrameHandle!T _handle;

    this(TcpStream connection, Codec codec)
    {
        _codec = codec;
        _connection = connection;

        connection.Received((Bytes bytes)
        {
            Buffer buffer;
            buffer.Append(bytes);

            T message = codec.Decode(buffer);
            
            if (_handle !is null)
            {
                _handler(message);
            }

            return DataHandleStatus.Done;
        });
    }

    void OnFrame(FrameHandle!T handle)
    {
        _handle = handle;
    }

    void Send(Object message) {
        Encoder encoder = _codec.GetEncoder();
        Buffer buf = encoder.Encode(message);
        string content = buf.toString();
        Tracef("Writting: %s", content);
        _connection.Write(buf.Data.data());
    }
}
