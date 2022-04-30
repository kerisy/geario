module gear.codec.Decoder;

import gear.buffer.Buffer;
import gear.buffer.Bytes;
import gear.Exceptions;
import gear.net.channel;

alias DecodingHandler = void delegate(Object);

/** 
 * 
 */
interface Decoder {
    void Decode(Bytes buf);

    void OnFrame(DecodingHandler handler);
}

/** 
 * 
 */
class AbstractDecoder : Decoder {

    protected DecodingHandler _handler;

    void Decode(Bytes buf) {
        implementationMissing();
    }
    
    void OnFrame(DecodingHandler handler) {
        _handler = handler;
    }
}
