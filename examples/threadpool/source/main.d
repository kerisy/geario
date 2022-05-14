
import geario.util.ThreadPool;

import std.stdio;

import core.thread;
import std.process;

void main()
{
    auto pool = new ThreadPool(2);
    Thread.sleep(1.seconds);
    
    for (int i = 0; i < 20; i++)
    {
        pool.Emplace(() {
            writeln("Writeln i: ", i,", Thread id: ", thisThreadID());
            Thread.sleep(1.seconds);
        });
    }

    getchar();

    writeln("Stopping....");
    
    pool.Stop();

    writeln("All done.");
}
