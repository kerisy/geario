module gear.codec.Framed;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

import gear.codec.Codec;

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
}
