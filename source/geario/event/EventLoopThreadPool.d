module geario.event.EventLoopThreadPool;

import geario.event.EventLoop;
import geario.util.ThreadPool;

import core.sync.mutex;
import core.thread;

class EventLoopThreadPool
{
public:

    this(size_t capacity)
    {
        _cur_index = 0;
        _capacity = capacity;
        _mutex_cur_idx = new Mutex;

        for (int i = 0; i < capacity; i++)
        {
            _loops[i] = new EventLoop;
        }

        Init();
    }

    ~this()
    {
        //
    }

    EventLoop GetNextLoop()
    {
        // _mutex_cur_idx.lock();
        scope (exit)
        {
            // _mutex_cur_idx.unlock();
            _cur_index++;
        }

        if (_cur_index == _capacity) {
            _cur_index = 0;
        }

        return _loops[_cur_index];
    }

 private:
    void Init()
    {
        foreach (EventLoop loop; _loops)
        {
            _threads ~= new Thread(&loop.StartLoop).start();
        }
    }

    size_t _capacity;
    EventLoop[size_t] _loops;
    Thread[] _threads;
    size_t _cur_index;
    Mutex _mutex_cur_idx;
}
