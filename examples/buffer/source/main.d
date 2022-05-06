import std.stdio;
import std.algorithm;
import std.string;
import std.conv;

import gear.logging.ConsoleLogger;

import gear.buffer.Buffer;
import gear.buffer.Bytes;

import nbuff.buffer;

void main(string[] args)
{
    // testCapacity1();
    // testCapacity2();
    // testCapacity3();
    // testCapacity4();
    // testResize();

    // testSplit1();
    // testSplit2();

    // testNbuff1();
    // testNbuff2();

    // testBytesWithThread();

	BufferTests bufferTests = new BufferTests();

	// bufferTests.testConstruct01();
	// bufferTests.testConstruct02();
	bufferTests.testRead1();


	getchar();
}

class BufferTests {

	void testConstruct01() {

		Bytes chunk1 = Bytes.WithCapacity(16);
		Bytes chunk2 = Bytes.WithCapacity(16);

		Infof("chunk1: %s", chunk1.toString());

		Buffer buffer;

        // FIXME: Needing refactor or cleanup -@zhangxueping at 2022-05-01T11:10:43+08:00
        // 
		buffer.Append(chunk1); // bug in ~this()
		buffer.Append(chunk2);

		Infof("buffer: %s", buffer.toString());
	}

	private Buffer buildBuffer() {

		Bytes chunk1 = Bytes.WithCapacity(16);
        chunk1.Put("12345");

		Bytes chunk2 = Bytes.WithCapacity(16);
        chunk1.Put("abcde");

		Infof("chunk1: %s", chunk1.toString());

		Buffer buffer;

		buffer.Append(chunk1); 
		buffer.Append(chunk2);

		Infof("buffer: %s", buffer.toString());

        return buffer;
	}

    void testRead1() {
        Buffer buffer = buildBuffer();

		Infof("buffer: %s", buffer.toString());

        Bytes chunk = buffer.Read();
		Infof("chunk1: %s", chunk.toString());
        
        chunk = buffer.Read();
		Infof("chunk2: %s", chunk.toString());
    }
}


void testBytesWithThread() {

}


void testNbuff2() {

    auto buffer1 = Nbuff.get(3);
    buffer1 = Nbuff.get(15);
    buffer1 = Nbuff.get(32);

    auto buffer2 = Nbuff.get(2049);
    auto buffer3 = Nbuff.get(128);
    auto buffer4 = Nbuff.get(1025);
}

void testNbuff1()
{
    import core.thread;

    MutableNbuffChunk buffer = Nbuff.get(16);
    buffer.data()[0] = 0x12;

    Thread th = new Thread(() {
        Nbuff b;
        b.append(buffer, 8);
    });

    th.start();

    // safe_tracef("here: %d", buffer.data.length);  // valid or invalid

    // getchar();
    
    // safe_tracef("here: %s", buffer.isNull());  // invalid

    Info("done");
}

void testSplit2()
{
    import std.container.dlist;

    DList!Bytes bytes;
}

    struct B
    {
        this(size_t capacity) {
        }

        void popFront();
        @property bool empty();
        @property int front();
    }

void testSplit1()
{
    Bytes a = Bytes.From("hello world");

    Bytes b = a.SplitOffset(5);

    a[0] = 'j';
    b[0] = '!';

    ubyte[] d1 = a.Chunk();
    Tracef("%s", cast(string) d1);
    assert(d1 == cast(ubyte[]) "jello");

    ubyte[] d2 = b.Chunk();
    Tracef("%s", cast(string) d2);
    Tracef("%(%02X, %)", d2);
    assert(d2 == cast(ubyte[]) "!world");

}

// void testResize()
// {
//     Bytes buffer;

//     buffer.Resize(3, 0x01);
//     ubyte[] chunk = buffer.Chunk;
//     Tracef("%(%02X, %)", chunk);
//     assert(buffer.Chunk == [0x1, 0x1, 0x1]);

//     Warning(buffer.toString());

//     buffer.Resize(2, 0x02);
//     chunk = buffer.Chunk;
//     Tracef("%(%02X, %)", chunk);
//     assert(buffer.Chunk == [0x1, 0x1]);
//     Warning(buffer.toString());

//     buffer.Resize(4, 0x03);
//     assert(buffer.Chunk == [0x1, 0x1, 0x3, 0x3]);
//     Warning(buffer.toString());
// }

// void testCapacity4()
// {
//     Bytes buffer = Bytes.From("hello");

//     ubyte[] data = buffer.AsArray();

//     data[0] = '1';
// }

// void testCapacity3()
// {
//     Bytes buffer = Bytes.From("hello");
//     for (size_t i; i < 20; i++)
//     {
//         buffer.Put(cast(byte) i);
//     }
//     Trace(buffer.toString());

//     buffer = Bytes.From(['a', 'b', 'c']);
//     Trace(buffer.toString());

//     buffer = buffer.GetBytes(2);
//     Trace(buffer.toString());
// }

// void testCapacity2()
// {

//     Bytes buffer = Bytes.WithCapacity(5);
//     buffer.Put("hello");
//     buffer.Reserve(64);
//     Trace(buffer.toString());
//     assert(buffer.Capacity() >= 69);
// }

// void testCapacity1()
// {
//     Bytes buffer = Bytes.WithCapacity(5);
//     buffer.Put('a');
//     buffer.Put('b');
//     buffer.Put('c');
//     buffer.Put('d');

//     Trace(buffer.toString());

//     assert(buffer.Capacity() == 5);

//     ubyte b = buffer.GetByte();
//     // b = buffer.GetByte();
//     Trace(buffer.toString());

//     buffer.Reserve(2);
//     Trace(buffer.toString());

//     assert(buffer.Capacity() == 5);
// }

// void main2(string[] args)
// {
//     Nbuff buff;

//     buff.append("abcde");

//     NbuffChunk d = buff.data;
//     auto dd = d.data;
//     Trace(typeid(dd));
//     Trace(dd);

//     buff.append("abcde");
//     dd = d.data;
//     // dd[0] = '1';

//     // auto d3 =  d.data;
//     // Trace(d3);

// }

