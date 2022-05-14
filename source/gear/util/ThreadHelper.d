/*
 * Gear - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.util.ThreadHelper;

import core.thread;

version (Posix) {
    import gear.system.syscall;

    ThreadID GetTid() {
        version(FreeBSD) {
            long tid;
            syscall(SYS_thr_self, &tid);
            return cast(ThreadID)tid;
        } else version(OSX) {
            return cast(ThreadID)syscall(SYS_thread_selfid);
        } else version(linux) {
            return cast(ThreadID)syscall(__NR_gettid);
        } else {
            return 0;
        }
    }
} else {
    import core.sys.windows.winbase: GetCurrentThreadId;
    ThreadID GetTid() {
        return GetCurrentThreadId();
    }
}