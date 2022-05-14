module geario.util.queue.Queue;

/**
 * 
 */
abstract class Queue(T)
{

    bool IsEmpty();

    T Pop();

    void Push(T task);

    void Clear();
}
