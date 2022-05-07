module codec.Encoder;

import gear.buffer.Buffer;

/** 
 * 
 */
interface Encoder(ET)
{
    Buffer Encode(ET message);
}
