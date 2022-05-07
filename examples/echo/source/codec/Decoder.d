module codec.Decoder;

import gear.buffer.Buffer;

/** 
 * 
 */
interface Decoder(DT)
{
    // -1 : Failed
    //  0 : Partial
    // >0 : Parsed length
    long Decode(ref Buffer buffer, ref DT message);
}
