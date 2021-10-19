module gear.codec.Encoder;

import gear.buffer.Buffer;
import gear.Exceptions;

/** 
 * 
 */
interface Encoder {

    Buffer Encode(Object message);

    void SetBufferSize(int size);
}

/** 
 * 
 */
class AbstractEncoder : Encoder {

    protected int _bufferSize = 256;

    void SetBufferSize(int size) {
        assert(size>0 || size == -1, "The size must be > 0.");
        if(size > 0)
            this._bufferSize = size;
    }

    Buffer Encode(Object message) {
        implementationMissing();
        return Buffer("");
    }
}
