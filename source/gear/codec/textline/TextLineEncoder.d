module gear.codec.textline.TextLineEncoder;

import gear.codec.textline.LineDelimiter;
import gear.codec.Encoder;

import gear.buffer.Buffer;
import gear.Exceptions;

import std.conv;


/**
 * A {@link ProtocolEncoder} which encodes a string into a text line
 * which ends with the _delimiter.
 */
class TextLineEncoder : AbstractEncoder {
    private enum string ENCODER = "encoder";

    private LineDelimiter _delimiter;

    private int maxLineLength = int.max;

    /**
     * Creates a new instance with the current default {@link Charset}
     * and {@link LineDelimiter#UNIX} _delimiter.
     */
    this() {
        this(LineDelimiter.UNIX);
    }

    /**
     * Creates a new instance with the current default {@link Charset}
     * and the specified <tt>_delimiter</tt>.
     * 
     * @param _delimiter The line _delimiter to use
     */
    this(string delimiter) {
        this(LineDelimiter(delimiter));
    }

    /**
     * Creates a new instance with the current default {@link Charset}
     * and the specified <tt>_delimiter</tt>.
     * 
     * @param _delimiter The line _delimiter to use
     */
    this(LineDelimiter delimiter) {
        if (LineDelimiter.AUTO == delimiter) {
            throw new IllegalArgumentException("AUTO _delimiter is not allowed for encoder.");
        }

        this._delimiter = delimiter;        
    }

    /**
     * @return the allowed maximum size of the encoded line.
     * If the size of the encoded line exceeds this value, the encoder
     * will throw a {@link IllegalArgumentException}.  The default value
     * is {@link Integer#MAX_VALUE}.
     */
    int GetMaxLineLength() {
        return maxLineLength;
    }

    /**
     * Sets the allowed maximum size of the encoded line.
     * If the size of the encoded line exceeds this value, the encoder
     * will throw a {@link IllegalArgumentException}.  The default value
     * is {@link Integer#MAX_VALUE}.
     * 
     * @param maxLineLength The maximum line length
     */
    void SetMaxLineLength(int maxLineLength) {
        if (maxLineLength <= 0) {
            throw new IllegalArgumentException("maxLineLength: " ~ maxLineLength.to!string());
        }

        this.maxLineLength = maxLineLength;
    }

    /**
     * {@inheritDoc}
     */
    override
    Buffer Encode(Object message) {

        string delimiterValue = _delimiter.GetValue();

        string value = message is null ? "" : message.toString();
        Buffer buf;
        buf.Append(value);

        if (buf.Length() > maxLineLength) {
            throw new IllegalArgumentException("Line length: " ~ buf.Length().to!string());
        }

        buf.Append(delimiterValue);

        return buf;
    }
}