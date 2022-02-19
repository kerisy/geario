module gear.codec.Framed;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

import gear.codec.Codec;
import gear.codec.Encoder;

import gear.net.TcpStream;
import gear.net.channel.Types;

import gear.logging.ConsoleLogger;

alias FrameHandler(T) = void delegate(T bufer);

/** 
 * 
 */
class Framed(T)
{
    private TcpStream _connection;
    private Codec _codec;
    private FrameHandler!T _handler;

    this(TcpStream connection, Codec codec)
    {
        _codec = codec;
        _connection = connection;
        
        codec.GetDecoder().OnFrame((Object frame)
        {
            if (_handler !is null)
            {
                _handler(cast(T)frame);
            }
        });

        connection.Received((Bytes bytes)
        {
            Buffer buffer;
            buffer.Append(bytes);

            DataHandleStatus status = codec.GetDecoder().Decode(buffer);

            version(GEAR_IO_DEBUG) {
                Trace("DataHandleStatus :", status);
            }

            return status;
        });
    }

    void OnFrame(FrameHandler!T handler)
    {
        _handler = handler;
    }

    void Send(Object message) {
        Encoder encoder = _codec.GetEncoder();
        Buffer buf = encoder.Encode(message);
        string content = buf.toString();
        Tracef("Writting: %s", content);
        _connection.Write(buf.Data.data());
    }
}
