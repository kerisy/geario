module gear.buffer.Bytes;

import nbuff.buffer;

import gear.logging.ConsoleLogger;

import std.conv;
import std.format;

/** 
 * https://docs.rs/bytes/1.0.1/bytes/struct.BytesMut.html
 * 
 *      +-------------------+------------------+------------------+
 *      | discardable bytes |  readable bytes  |  writable bytes  |
 *      |                   |     (CONTENT)    |                  |
 *      +-------------------+------------------+------------------+
 *      |                   |                  |                  |
 *      0      <=      readerIndex   <=   writerIndex    <=    capacity
 */
struct Bytes {
    private MutableMemoryChunk _chunk;
    private ubyte[] _data;

    private size_t _readerIndex;
    private size_t _writerIndex;
    private size_t _capacity;   

    this(size_t capacity) {
        _capacity = capacity;
        _readerIndex = 0;
        _writerIndex = 0;
        _chunk = MutableMemoryChunk(capacity);
        _data = _chunk.data();
    }


    this(MutableMemoryChunk chunk) {
        _capacity = chunk.size();
        _readerIndex = 0;
        _writerIndex = 0;
        _chunk = chunk;
        _data = _chunk.data();
    }

    /** 
     * Creates a new BytesMut with the specified capacity.
     * The returned BytesMut will be able to hold at least capacity bytes without reallocating.
     * It is important to note that this function does not specify the length of the returned BytesMut, but only the capacity.
     * 
     * Params:
     *   size = 
     * Returns: 
     */
    static Bytes WithCapacity(size_t size) {
        return Bytes(size);
    }

    static Bytes From(string content) {
        Bytes buffer = Bytes(content.length);
        buffer.Put(content);
        return buffer;
    }
 
    static Bytes From(const(ubyte)[] data) {
        Bytes buffer = Bytes(data.length);
        buffer.Put(data);
        return buffer;
    }

    // Bytes ShallowClone() {
    //     Bytes other = this;

    //     other.

    //     return other;
    // }

    private void CheckIndex(size_t index) {
        CheckIndex(index, 1);
    }

    private void CheckIndex(size_t index, size_t fieldLength) {
        if (index + fieldLength > _capacity) {
            throw new Exception(format("index: %d, length: %d (expected: range(0, %d))",
                    index, fieldLength, _capacity));
        }        
    }

    private void CheckReadableBytes(size_t minimumReadableBytes) {
        if (minimumReadableBytes < 0) {
            throw new Exception("minimumReadableBytes: " ~ minimumReadableBytes.to!string() ~ " (expected: >= 0)");
        }
        if (_readerIndex + minimumReadableBytes > _writerIndex) {
            throw new Exception(format("readerIndex(%d) + length(%d) exceeds writerIndex(%d): %s",
                    _readerIndex, minimumReadableBytes, _writerIndex, this.toString()));
        }
    }

    private void EnsureWritable(size_t minWritableBytes) {

        version(GEAR_DEBUG_MORE) {
            Tracef("minWritableBytes: %d, WritableBytes: %d", minWritableBytes, WritableBytes());
        }

        if (minWritableBytes <= WritableBytes()) {
            return;
        }

        Reserve(minWritableBytes);
    }

    /** 
     * Returns: the number of bytes the BytesMut can hold without reallocating.
     */
    size_t Capacity() {
        return _capacity;
    }

    /** 
     * 
     * Returns: the number of bytes contained in this BytesMut.
     */
    size_t Length() {
        return _writerIndex - _readerIndex;
    }

    /** 
     * 
     * Returns: true if the BytesMut has a length of 0.
     */
    bool IsEmpty() {
        return _writerIndex == _readerIndex;
    }

    size_t ReaderIndex() {
        return _readerIndex;
    }

    void ReaderIndex(size_t index) {
        _readerIndex = index;
    }

    /** 
     * Advance the internal cursor of the Buf
     * 
     * Params:
     *   index = 
     */
    void Advance(size_t count) {
        _readerIndex += count;
    }

    size_t ReadableBytes() {
        return _writerIndex - _readerIndex; 
    }

    size_t WriterIndex() {
        return _writerIndex;
    }

    void WriterIndex(size_t index) {
        _writerIndex = index;
    }

    size_t WritableBytes() {
        return _capacity - _writerIndex;
    }

    /** 
     * Reserves capacity for at least additional more bytes to be inserted into the given BytesMut.
     * More than additional bytes may be reserved in order to avoid frequent reallocations. A call to reserve may result in an allocation.
     * Before allocating new buffer space, the function will attempt to reclaim space in the existing buffer. If the current handle references a small view in the original buffer and all other handles have been dropped, and the requested capacity is less than or equal to the existing buffer's capacity, then the current view will be copied to the front of the buffer and the handle will take ownership of the full buffer.
     * 
     * Params:
     *   additional = 
     */
    void Reserve(size_t additional) {

        // Normalize the current capacity to the power of 2.
        size_t len = Length();
        size_t oldCapacity = _capacity - len;
        ubyte[] oldArray = _data;
        
        if (additional > oldCapacity) {
            size_t newCapacity = CalculateNewCapacity(additional + len);
            version(GEAR_DEBUG) {
                Tracef("_readerIndex: %d, additional: %d, newCapacity: %d, oldCapacity: %d", 
                    _readerIndex, additional, newCapacity, oldCapacity);
            }

            _chunk = MutableMemoryChunk(newCapacity);
            ubyte[] newArray = _chunk.data();

            newArray[0..len] = oldArray[_readerIndex .. _writerIndex];
            _data = newArray;
            _readerIndex = 0;
            _writerIndex = len;
            _capacity = newCapacity;
        } else if(len > 0) {
            version(GEAR_DEBUG) {
                Tracef("Moving data: %d bytes, _readerIndex: %d, additional: %d", len, _readerIndex, additional);
            }
            import core.stdc.string;
            ubyte[] srcData = _data[_readerIndex .. _writerIndex];
            // memmove(_data.ptr, srcData.ptr, len);
            memcpy(_data.ptr, srcData.ptr, len);
            _readerIndex = 0;
            _writerIndex = len;
        }
    }

    /** 
     * Resizes the buffer so that len is equal to size.
     * If size is greater than len, the buffer is extended by the difference with each additional byte set to value. If new_len is less than len, the buffer is simply truncated.
     * 
     * Params:
     *   size = 
     */
    void Resize(size_t size, ubyte value = 0) {
        size_t len = this.Length();
        Tracef("size: %d, Length: %d, value: %d", size, Length(), value);
        if(size > len) {
            size_t additional = size - len;
            this.Reserve(additional);
            _writerIndex += additional;
            ubyte[] chunk = this.Chunk();
            chunk[$ - additional .. $] = value;

        } else {
            this.Truncate(size);
        }
    }

    /** 
     * Shortens the buffer, keeping the first len bytes and dropping the rest.
     * If len is greater than the buffer's current length, this has no effect.
     * 
     * Params:
     *   size = 
     */
    void Truncate(size_t len) {
        if(len < this.Length()) {
            _writerIndex = _readerIndex + len;
        }
    }

    /** 
     * Splits the bytes into two at the given index.
     * Afterwards self contains elements [0, at), and the returned BytesMut contains elements [at, capacity).
     * 
     * Params:
     *   index = 
     * Returns: 
     */
    Bytes SplitOffset(size_t at) {
        assert(at <= this.Capacity(), format("out of bounds: %d <= %d", at, this.Capacity()));

        Bytes other = Bytes.From(_data[at..$]);
        other._readerIndex = 0;
        other._writerIndex = _writerIndex - at;

        _writerIndex = at;
        _capacity = _capacity - at;

        return other;
    }

    /** 
     * Removes the bytes from the current view, returning them in a new BytesMut handle.
     * 
     * Returns: 
     */
    Bytes Split() {
        return SplitTo(this.Length());
    }

    /** 
     * Splits the buffer into two at the given index.
     * 
     * Params:
     *   length = 
     * Returns: 
     */
    Bytes SplitTo(size_t length) {
        assert(length <= this.Length(), format("out of bounds: %d <= %d", length, this.Length()));

        ubyte[] chunk = this.Chunk();
        _readerIndex += length;
        _capacity -= length;

        Bytes other = Bytes.From(chunk[0..length]);

        // TODO: Tasks pending completion -@zhangxueping at 2021-07-06T16:06:59+08:00
        // MutableMemoryChunk should be refrenece counted
        // 
        // Bytes other = this;

        // other._writerIndex = other._readerIndex + length;
        // other._capacity = other._writerIndex;

        // _capacity -= other._capacity;
        // _readerIndex += length;

        return other;
    }

    /** 
     * Clears the buffer, removing all data.
     */
    void Clear() {
        _readerIndex = _writerIndex = 0;
    }
    
    void Put(ubyte value) {
        EnsureWritable(1);
        _data[_writerIndex] = value;
        _writerIndex++;
    }

    void Put(byte value) {
        EnsureWritable(1);
        _data[_writerIndex] = value;
        _writerIndex++;
    }

    void Put(char value) {
        EnsureWritable(1);
        _data[_writerIndex] = value;
        _writerIndex++;
    }

    void Put(string value) {
        size_t len = value.length;
        if(len == 0) return;
        EnsureWritable(len);
        _data[_writerIndex .. _writerIndex + len] = cast(ubyte[])value[0 .. $];
        _writerIndex += len;
    }

    void Put(const(ubyte)[] value) {
        size_t len = value.length;
        if(len == 0) return;
        EnsureWritable(len);

        for(size_t i=0; i<len; i++) {
            _data[_writerIndex + i] = value[i];
        }

        // bug
        // _data[_writerIndex .. _writerIndex + len] = value[0 .. len];
        _writerIndex += len;
    }    

    ubyte GetByte() {
        CheckReadableBytes(1);
        ubyte b = _data[_readerIndex];
        _readerIndex++;
        return b;
    }

    Bytes GetBytes(size_t length) {
        CheckReadableBytes(length);
        ubyte[] data = _data[_readerIndex .. _readerIndex + length];

        _readerIndex += length;
        return Bytes.From(data);
    }

    bool HasRemaining() {
        return _writerIndex > _readerIndex; 
    }

    /** 
     * 
     * Returns: 
     * The number of bytes between the current position and the end of the buffer.
     * This value is greater than or equal to the length of the slice returned by chunk().
     */
    size_t Remaining() {
        return ReadableBytes();
    }
    
    /** 
     * 
     * Returns: Returns a slice starting at the current position and of length between 0 and remaining(). Note that this can return shorter slice (this allows non-continuous internal representation).
     * This is a lower level function. Most operations are done with other functions.
     */
    ubyte[] Chunk() {
        return _data[_readerIndex .. _writerIndex];
    }    

    ref ubyte opIndex(size_t index) {
        return _data[_readerIndex + index];
    }

    ubyte[] opSlice(size_t start, size_t end) {
        return _data[_readerIndex + start .. _readerIndex + end];
    }

    /** 
     * 
     * Returns: The backing byte array of this buffer.
     */
    ubyte[] AsArray() {
        return _data[];
    }

    string toString() {
        return format("readerIndex: %d, writerIndex: %d, length: %d, capacity: %d", 
            _readerIndex, _writerIndex, Length(), _capacity);
    }
}


private size_t CalculateNewCapacity(size_t minNewCapacity) {

    enum size_t threshold = 1048576 * 4; // 4 MiB page

    if (minNewCapacity == threshold) {
        return threshold;
    }

    // If over threshold, do not double but just increase by threshold.
    if (minNewCapacity > threshold) {
        size_t newCapacity = minNewCapacity / threshold * threshold;
        newCapacity += threshold;
        return newCapacity;
    }

    // Not over threshold. Double up to 4 MiB, starting from 16.
    size_t newCapacity = 16;
    while (newCapacity < minNewCapacity) {
        newCapacity <<= 1;
    }

    return newCapacity;
}