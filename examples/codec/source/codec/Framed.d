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
    private Codec!T _codec;
    private FrameHandle!T _handle;
    private Buffer _buffer;

    this(TcpStream connection, Codec!T codec)
    {
        _codec = codec;
        _connection = connection;

        connection.Received((Bytes bytes)
        {
            _buffer.Append(bytes);

            T message;

            long parsed = codec.Decode(_buffer, message);

            _buffer.Pop(parsed);
            
            if (_handle !is null)
            {
                _handle(message);
            }
        });
    }

    void OnFrame(FrameHandle!T handle)
    {
        _handle = handle;
    }

    void Send(T message)
    {
        Buffer buf = _codec.Encode(message);

        // for debug
        string content = buf.toString();
        Tracef("Writting: %s", content);

        _connection.Write(buf.Data.data());
    }
}
