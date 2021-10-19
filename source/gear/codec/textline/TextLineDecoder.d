module gear.codec.textline.TextLineDecoder;

import gear.codec.textline.LineDelimiter;
import gear.codec.Decoder;
import gear.Exceptions;

import gear.buffer.Buffer;
import gear.logging.ConsoleLogger;
import gear.net.channel;
import nbuff;


import std.algorithm;
import std.conv;
import std.range;

/** 
 * 
 */
class TextLineFrame {
    string line;
}


/**
 * A {@link ProtocolDecoder} which decodes a text line into a string.
 *
 */
class TextLineDecoder : AbstractDecoder {
    private enum string CONTEXT = "decoder";

    /** The _delimiter used to determinate when a line has been fully decoded */
    private LineDelimiter _delimiter;

    /** An Buffer containing the _delimiter */
    private Buffer _delimBuf;

    /** An Buffer containing the _delimiter */
    private Buffer _delRestBuf;

    /** The default maximum Line length. Default to 1024. */
    private int maxLineLength = 1024;

    /** The default maximum buffer length. Default to 128 chars. */
    private int bufferLength = 128;

    protected Object[string] _attributes;

    /**
     * Creates a new instance with the current default {@link Charset}
     * and {@link LineDelimiter#AUTO} _delimiter.
     */
    this() {
        this(LineDelimiter.AUTO);
    }


    /**
     * Creates a new instance with the current default {@link Charset}
     * and the specified <tt>delimiter</tt>.
     * 
     * @param delimiter The line delimiter to use
     */
    this(LineDelimiter delimiter) {
        this._delimiter = delimiter;

        // Convert _delimiter to Buffer if not done yet.
        if (_delimBuf.Empty()) {
            Buffer tmp;//  Buffer.allocate(2).setAutoExpand(true);

            try {
                if( !delimiter.GetValue().empty )
                {
                    tmp.Append(delimiter.GetValue());
                }
            } catch (CharacterCodingException cce) {
                Warning(cce);
            }

            _delimBuf.opAssign(tmp);
        }        
    }

    /**
     * @return the allowed maximum size of the line to be decoded.
     * If the size of the line to be decoded exceeds this value, the
     * decoder will throw a {@link BufferDataException}.  The default
     * value is <tt>1024</tt> (1KB).
     */
    int GetMaxLineLength() {
        return maxLineLength;
    }

    /**
     * Sets the allowed maximum size of the line to be decoded.
     * If the size of the line to be decoded exceeds this value, the
     * decoder will throw a {@link BufferDataException}.  The default
     * value is <tt>1024</tt> (1KB).
     * 
     * @param maxLineLength The maximum line length
     */
    void SetMaxLineLength(int maxLineLength) {
        if (maxLineLength <= 0) {
            throw new IllegalArgumentException("maxLineLength (" ~ 
                maxLineLength.to!string() ~ ") should be a positive value");
        }

        this.maxLineLength = maxLineLength;
    }

    /**
     * Sets the default buffer size. This buffer is used in the Context
     * to store the decoded line.
     *
     * @param bufferLength The default bufer size
     */
    void SetBufferLength(int bufferLength) {
        if (bufferLength <= 0) {
            throw new IllegalArgumentException("bufferLength (" ~ 
                maxLineLength.to!string() ~ ") should be a positive value");

        }

        this.bufferLength = bufferLength;
    }

    /**
     * @return the allowed buffer size used to store the decoded line
     * in the Context instance.
     */
    int GetBufferLength() {
        return bufferLength;
    }

    /**
     * {@inheritDoc}
     */
    override
    DataHandleStatus Decode(Buffer buf) { 
        Context ctx = GetContext();

        if (LineDelimiter.AUTO == _delimiter) {
            return DecodeAuto(ctx, buf);
        } else {
            return DecodeNormal(ctx, buf);
        }
    }

    /**
     * @return the context for this connection
     * 
     * @param connection The connection for which we want the context
     */
    private Context GetContext() {
        Context ctx;
        ctx = cast(Context) GetAttribute(CONTEXT);

        if (ctx is null) {
            ctx = new Context(bufferLength);
            SetAttribute(CONTEXT, ctx);
        }

        return ctx;
    }


    /**
     * {@inheritDoc}
     */
    void Dispose() {
        Context ctx = cast(Context) GetAttribute(CONTEXT);

        if (ctx !is null) {
            RemoveAttribute(CONTEXT);
        }
    }

    /**
     * Decode a line using the default _delimiter on the current system
     */
    private DataHandleStatus DecodeAuto(Context ctx, Buffer inBuffer) { 
        DataHandleStatus resultStatus = DataHandleStatus.Done;

        int matchCount = ctx.getMatchCount();

        string strTmp = _delRestBuf.toString() ~ inBuffer.toString();
        _delRestBuf.Pop(_delRestBuf.Length);
        _delRestBuf.Append(strTmp);

        //Tracef("_delRestBuf : %s", _delRestBuf.toString());
        // Try to find a match
        int oldPos = 0;
        int oldLimit = cast(int)_delRestBuf.Length();

        int nPos = 0;
        while (nPos < oldLimit) {
            byte b = _delRestBuf.Data[nPos];
            
            bool matched = false;
            switch (b) {
            case '\r':
                // Might be Mac, but we don't auto-detect Mac EOL
                // to avoid confusion.
                matchCount++;
                break;

            case '\n':
                // UNIX
                matchCount++;
                matched = true;
                break;

            default:
                matchCount = 0;
            }

            if (matched) {
                // Found a match.
                auto chunk = _delRestBuf.Data[oldPos..nPos];
                Buffer tmp = Buffer(chunk.data);

                TextLineFrame frame = new TextLineFrame();
                frame.line = cast(string)chunk.data.dup;

                if(_handler !is null) {
                    _handler(frame);
                }

                ctx.append(tmp);

                oldPos = nPos+1;
                
            }
            nPos++;
        }

        // Put remainder to buf.
        if( oldPos < oldLimit || oldPos == 0 )
        {
            auto last = _delRestBuf.Data[oldPos..oldLimit];
            string strLast = cast(string)last.data;
            ctx.append(Buffer(last.data));
            _delRestBuf.Pop(_delRestBuf.Length);
            _delRestBuf.Append(strLast);
            //Tracef("inBuffer : %s, oldPos : %d, limit : %d ||| strLast : %s, strLen : %d", _delRestBuf.toString(), oldPos, oldLimit, strLast, strLast.length);
        }

        if( oldPos >= oldLimit )
        {
            _delRestBuf.Pop(_delRestBuf.Length);
        }

        ctx.setMatchCount(matchCount);
        matchCount = 0;
        
        return resultStatus;
    }

    /**
     * Decode a line using the _delimiter defined by the caller
     */
    private DataHandleStatus DecodeNormal(Context ctx, Buffer inBuffer) { 
        DataHandleStatus resultStatus = DataHandleStatus.Done;
        int matchCount = ctx.getMatchCount();

        // Try to find a match
        int oldPos = 0;
        int oldLimit = cast(int)inBuffer.Length();

        int nPos = 0;
        while (nPos < oldLimit) {
            byte b = inBuffer[nPos];

            if (_delimBuf[matchCount] == b) {
                matchCount++;

                if (matchCount == _delimBuf.Length()) {
                    // Found a match.
                    auto chunk = inBuffer.Data[oldPos..nPos];

                    TextLineFrame frame = new TextLineFrame();
                    frame.line = cast(string)chunk.data.dup;

                    if(_handler !is null) {
                        _handler(frame);
                    }    

                    ctx.append(Buffer(chunk.data));
                    oldPos = nPos + 1;
                    matchCount = 0;
                }
            } else {
                // fix for DIRMINA-506 & DIRMINA-536
                matchCount = 0;
            }
            nPos++;
        }

        // Put remainder to buf.
        if( oldPos < oldLimit )
        {
            auto last = inBuffer.Data[oldPos..oldLimit];
            ctx.append(Buffer(last.data));
        }

        ctx.setMatchCount(matchCount);
        matchCount = 0;

        inBuffer.Clear();
        return resultStatus;
    }

        /**
     * {@inheritDoc}
     */
    Object GetAttribute(string key) {
        return _attributes.get(key, null);
    }


    /**
     * {@inheritDoc}
     */
    Object SetAttribute(string key, Object value) {
        auto itemPtr = key in _attributes;
        Object oldValue = null;
        if(itemPtr !is null) {
            oldValue = *itemPtr;
        }
        _attributes[key] = value;
        return oldValue;
    }


    /**
     * {@inheritDoc}
     */
    Object RemoveAttribute(string key) {
        auto itemPtr = key in _attributes;
        if(itemPtr is null) {
            return null;
        } else {
            Object oldValue = *itemPtr;
            _attributes.remove(key);
            return oldValue;
        }
    }


    /**
     * A Context used during the decoding of a lin. It stores the decoder,
     * the temporary buffer containing the decoded line, and other status flags.
     *
     * @author <a href="mailto:dev@directory.apache.org">Apache Directory Project</a>
     * @version $Rev$, $Date$
     */
    private class Context {
        /** The decoder */
        // private final CharsetDecoder decoder;

        /** The temporary buffer containing the decoded line */
        private Buffer _buf;

        /** The number of lines found so far */
        private int matchCount = 0;

        /** A counter to signal that the line is too long */
        private int overflowPosition = 0;

        /** Create a new Context object with a default buffer */
        private this(int bufferLength) {
            // decoder = charset.newDecoder();
            // buf = Buffer.allocate(bufferLength).setAutoExpand(true);
            //buf = BufferUtils.allocate(bufferLength);
        }

        Buffer getBuffer() {
            return _buf;
        }

        int getOverflowPosition() {
            return overflowPosition;
        }

        int getMatchCount() {
            return matchCount;
        }

        void setMatchCount(int matchCount) {
            this.matchCount = matchCount;
        }

        void reset() {
            overflowPosition = 0;
            matchCount = 0;
            // decoder.reset();
        }

        void append(Buffer buffer) {
            if (overflowPosition != 0) {
                discard(buffer);
            } else if (_buf.Length() > maxLineLength - buffer.Length()) {
                overflowPosition = cast(int)_buf.Length();
                _buf.Clear();
                discard(buffer);
            } else {
                auto last = buffer.Data();
                _buf.Append(last);
            }
        }

        private void discard(Buffer buffer) {
            if (int.max - buffer.Length() < overflowPosition) {
                overflowPosition = int.max;
            } else {
                overflowPosition += buffer.Length();
            }
        }
    }
}