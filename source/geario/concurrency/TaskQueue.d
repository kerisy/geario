// module geario.concurrency.TaskQueue;

// import core.atomic;

// // #include <atomic>
// // #include <vector>
// // #include <cassert>
// // #include <cstdint>
// // #include <cstddef>
// // #include <cstdlib>

// class TaskQueue(T)
// {
// // static_assert(std::is_pointer_v<T>, "T must be a pointer type");

// struct Array {

//     long _c;
//     long _m;

//     atomic!T _s;

//     this(long c)
//     {
//         _c = c;
//         _m = c-1;
//         _s = &c;
//         //   _ {new std::atomic<T>[static_cast<size_t>(C)]};
//     }

//     long capacity()
//     {
//         return _c;
//     }

//     void push(long i, T o)
//     {
//         _s[i & M].store(o, std::memory_order_relaxed);
//     }

//     T pop(long i)
//     {
//         return _s[i & M].load(std::memory_order_relaxed);
//     }

//     Array* resize(long b, long t)
//     {
//         Array* ptr = new Array {2*C};
//         for(long i=t; i!=b; ++i) {
//             ptr->push(i, pop(i));
//         }
//         return ptr;
//     }

// // Doubling the alignment by 2 seems to generate the most
// // decent performance.
//     atomic!long _top;
//     atomic!long _bottom;
//     atomic!<Array*> _array;
//     vector!<Array*> _garbage;

// public:

//     /**
//     @brief constructs the queue with a given capacity

//     @param capacity the capacity of the queue (must be power of 2)
//     */
//     this(long capacity = 1024)
//     {
//         _top.store(0, std::memory_order_relaxed);
//         _bottom.store(0, std::memory_order_relaxed);
//         _array.store(new Array{c}, std::memory_order_relaxed);
//         _garbage.reserve(32);
//     }

//     /**
//     @brief destructs the queue
//     */
//     ~this()
//     {
//         for(auto a : _garbage) {
//             delete a;
//         }
//     }

//     /**
//     @brief queries if the queue is empty at the time of this call
//     */
//     bool empty()
//     {
//         long b = _bottom.load(std::memory_order_relaxed);
//         long t = _top.load(std::memory_order_relaxed);
//         return (b <= t);
//     }

//     /**
//     @brief queries the number of items at the time of this call
//     */
//     size_t size()
//     {
//         long b = _bottom.load(std::memory_order_relaxed);
//         long t = _top.load(std::memory_order_relaxed);
//         return static_cast<size_t>(b >= t ? b - t : 0);
//     }

//     /**
//     @brief queries the capacity of the queue
//     */
//     long capacity()
//     {
//         return _array.load(std::memory_order_relaxed)->capacity();
//     }

//     /**
//     @brief inserts an item to the queue

//     Only the owner thread can insert an item to the queue.
//     The operation can trigger the queue to resize its capacity
//     if more space is required.

//     @tparam O data type

//     @param item the item to push to the queue
//     */
//     void push(T item)
//     {
//         long b = _bottom.load(std::memory_order_relaxed);
//         long t = _top.load(std::memory_order_acquire);
//         Array* a = _array.load(std::memory_order_relaxed);

//         // queue is full
//         if(a->capacity() - 1 < (b - t)) {
//             Array* tmp = a->resize(b, t);
//             _garbage.push_back(a);
//             std::swap(a, tmp);
//             _array.store(a, std::memory_order_release);
//             // Note: the original paper using relaxed causes t-san to complain
//             //_array.store(a, std::memory_order_relaxed);
//         }

//         a->push(b, o);
//         std::atomic_thread_fence(std::memory_order_release);
//         _bottom.store(b + 1, std::memory_order_relaxed);
//     }

//     /**
//     @brief pops out an item from the queue

//     Only the owner thread can pop out an item from the queue.
//     The return can be a nullptr if this operation failed (empty queue).
//     */
//     T pop()
//     {
//         long b = _bottom.load(std::memory_order_relaxed) - 1;
//         Array* a = _array.load(std::memory_order_relaxed);
//         _bottom.store(b, std::memory_order_relaxed);
//         std::atomic_thread_fence(std::memory_order_seq_cst);
//         long t = _top.load(std::memory_order_relaxed);

//         T item {nullptr};

//         if(t <= b) {
//             item = a->pop(b);
//             if(t == b) {
//             // the last item just got stolen
//             if(!_top.compare_exchange_strong(t, t+1,
//                                             std::memory_order_seq_cst,
//                                             std::memory_order_relaxed)) {
//                 item = nullptr;
//             }
//             _bottom.store(b + 1, std::memory_order_relaxed);
//             }
//         }
//         else {
//             _bottom.store(b + 1, std::memory_order_relaxed);
//         }

//         return item;
//     }

//     /**
//     @brief steals an item from the queue

//     Any threads can try to steal an item from the queue.
//     The return can be a nullptr if this operation failed (not necessary empty).
//     */
//     T steal()
//     {
//         long t = _top.load(std::memory_order_acquire);
//         std::atomic_thread_fence(std::memory_order_seq_cst);
//         long b = _bottom.load(std::memory_order_acquire);

//         T item {nullptr};

//         if(t < b) {
//             Array* a = _array.load(std::memory_order_consume);
//             item = a->pop(t);
//             if(!_top.compare_exchange_strong(t, t+1,
//                                             std::memory_order_seq_cst,
//                                             std::memory_order_relaxed)) {
//             return nullptr;
//             }
//         }

//         return item;
//     }
// }
