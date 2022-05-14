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

module gear.system.syscall;

@system:
version(Posix):

extern (C) nothrow @nogc size_t syscall(size_t ident, ...);

version(D_InlineAsm_X86_64)
{
    version(linux) public import gear.system.syscall.os.Linux;
    else version(OSX) public import gear.system.syscall.os.OSX;
    else version(FreeBSD) public import gear.system.syscall.os.FreeBSD;
    else static assert(false, "Not supoorted OS.");
}
else version(AArch64)
{
    version(linux) public import gear.system.syscall.os.Linux;
    else version(OSX) public import gear.system.syscall.os.OSX;
    else version(FreeBSD) public import gear.system.syscall.os.FreeBSD;
    else static assert(false, "Not supoorted OS.");
}
else static assert(false, "The syscall() only supoorted for [x86_64,AArch64].");
