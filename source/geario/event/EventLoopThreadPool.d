module geario.event.EventLoopThreadPool;

import geario.event.EventLoop;
import geario.util.ThreadPool;

import core.sync.mutex;

class EventLoopThreadPool
{
public:

    this(size_t capacity)
    {
        _cur_index = 0;
        _capacity = capacity;
        _mutex_cur_idx = new Mutex;
        _pool = new ThreadPool(_capacity);

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
        _mutex_cur_idx.lock();
        scope (exit)
            _mutex_cur_idx.unlock();

        if (_cur_index == _capacity) {
            _cur_index = 0;
        }

        return _loops[_cur_index++];
    }

 private:
    void Init()
    {
        foreach (EventLoop loop; _loops)
        {
            _pool.Emplace(&loop.StartLoop);
        }
    }

    size_t _capacity;
    ThreadPool _pool;
    EventLoop[size_t] _loops;
    size_t _cur_index;
    Mutex _mutex_cur_idx;
}
