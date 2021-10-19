module gear.codec.Decoder;

import gear.buffer.Buffer;
import gear.Exceptions;
import gear.net.channel;

alias DecodingHandler = void delegate(Object);

/** 
 * 
 */
interface Decoder {
    DataHandleStatus Decode(Buffer buf);

    void OnFrame(DecodingHandler handler);
}

/** 
 * 
 */
class AbstractDecoder : Decoder {

    protected DecodingHandler _handler;

    DataHandleStatus Decode(Buffer buf) {
        implementationMissing();

        return DataHandleStatus.Done;
    }
    
    void OnFrame(DecodingHandler handler) {
        _handler = handler;
    }
}
