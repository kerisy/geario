module gear.codec.Codec;

import gear.codec.Decoder;
import gear.codec.Encoder;


/**
 * Provides {@link Encoder} and {@link Decoder} which translates
 * binary or  specific data into message object and vice versa.
 */
interface Codec {
    /**
     * Returns a new (or reusable) instance of {@link Encoder} which
     * encodes message objects into binary or -specific data.
     * 
     * @param connection The current connection
     * @return The encoder instance
     * @throws Exception If an error occurred while retrieving the encoder
     */
    Encoder GetEncoder();

    /**
     * Returns a new (or reusable) instance of {@link Decoder} which
     * decodes binary or -specific data into message objects.
     * 
     * @param connection The current connection
     * @return The decoder instance
     * @throws Exception If an error occurred while retrieving the decoder
     */
    Decoder GetDecoder();
}