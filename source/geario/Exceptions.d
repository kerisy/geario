/*
 * Geario - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module geario.Exceptions;

import core.exception;
import std.exception;

void implementationMissing(string name = __FUNCTION__, string file = __FILE__, int line = __LINE__)(
        bool CanThrow = true) {
    if (CanThrow)
        throw new Exception("Implementation missing: " ~ name, file, line);
    else {
        version (Posix) {
            import std.stdio;

            enum PRINT_COLOR_NONE = "\033[m";
            enum PRINT_COLOR_YELLOW = "\033[1;33m";
            stderr.writefln(PRINT_COLOR_YELLOW ~ "Implementation missing %s, in %s:%d" ~ PRINT_COLOR_NONE,
                    name, file, line);
        } else version(Windows) {
            import geario.system.WindowsHelper;
            import core.sys.windows.wincon;
            import std.format;
            string msg = format("Implementation missing %s, in %s:%d", name, file, line);
            ConsoleHelper.writeWithAttribute(msg, FOREGROUND_GREEN | FOREGROUND_RED);
        } else {
            assert(false, "Unsupported OS.");
        }
    }
}

mixin template BasicExceptionCtors() {
    this(size_t line = __LINE__, string file = __FILE__) @nogc @safe pure nothrow {
        super("", file, line, null);
    }

    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }

    this(Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow {
        assert(next !is null);
        super(next.msg, file, line, next);
    }

    // mixin basicExceptionCtors;
}

class ClassNotFoundException : Exception {
    mixin BasicExceptionCtors;
}

class NotImplementedException : Exception {
    mixin BasicExceptionCtors;
}

class NotSupportedException : Exception {
    mixin BasicExceptionCtors;
}

class IllegalArgumentException : Exception {
    mixin BasicExceptionCtors;
}

/** 
 * 
 */
class RuntimeException : Exception {
    this(Throwable ex) {
        super(ex.msg, ex);
    }

    /++
        Params:
            msg  = The message for the exception.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    +/
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }

    /++
        Params:
            msg  = The message for the exception.
            next = The previous exception in the chain of exceptions.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
    +/
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }
    // mixin BasicExceptionCtors;
}

class ExecutionException : Exception {
    mixin BasicExceptionCtors;
}

class InterruptedException : Exception {
    mixin BasicExceptionCtors;
}

class ParseException : Exception {
    mixin BasicExceptionCtors;
}

class CloneNotSupportedException : Exception {
    mixin BasicExceptionCtors;
}

class TimeoutException : Exception {
    mixin BasicExceptionCtors;
}

class FileNotFoundException : Exception {
    mixin BasicExceptionCtors;
}

class IOException : Exception {
    mixin BasicExceptionCtors;
}

class CharacterCodingException : IOException {
    mixin BasicExceptionCtors;
}

class ClosedChannelException : IOException {
    mixin BasicExceptionCtors;
}

class MalformedURLException : IOException {
    mixin BasicExceptionCtors;
}

class InterruptedIOException : IOException {
    mixin BasicExceptionCtors;
}

class RemoteException : IOException {
    mixin BasicExceptionCtors;
}

class UnsupportedEncodingException : IOException {
    mixin BasicExceptionCtors;
}

class AsynchronousCloseException : ClosedChannelException {
    mixin BasicExceptionCtors;
}

class CommonRuntimeException : RuntimeException {
    mixin BasicExceptionCtors;
}

class IndexOutOfBoundsException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NegativeArraySizeException : RuntimeException {
    mixin BasicExceptionCtors;
}

class ReadOnlyBufferException : RuntimeException {
    mixin BasicExceptionCtors;
}

class BufferUnderflowException : RuntimeException {
    mixin BasicExceptionCtors;
}

class BufferOverflowException : RuntimeException {
    mixin BasicExceptionCtors;
}

class UnsupportedOperationException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NoSuchElementException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NumberFormatException : IllegalArgumentException {
    mixin BasicExceptionCtors;
}

class NullPointerException : RuntimeException {
    mixin BasicExceptionCtors;
}

class EofException : RuntimeException {
    mixin BasicExceptionCtors;
}

class SecureNetException : RuntimeException {
    mixin BasicExceptionCtors;
}

class ArithmeticException : RuntimeException {
    mixin BasicExceptionCtors;
}

class IllegalStateException : Exception {
    mixin BasicExceptionCtors;
}

class InvalidMarkException : IllegalStateException {
    mixin BasicExceptionCtors;
}

class WritePendingException : IllegalStateException {
    mixin BasicExceptionCtors;
}

class CancellationException : IllegalStateException {
    mixin BasicExceptionCtors;
}

class GeneralSecurityException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateException : GeneralSecurityException {
    mixin BasicExceptionCtors;
}

class NoSuchAlgorithmException : GeneralSecurityException {
    mixin BasicExceptionCtors;
}

class ConcurrentModificationException : RuntimeException {
    mixin BasicExceptionCtors;
}

class InternalError : Exception {
    mixin BasicExceptionCtors;
}

class CRLException : GeneralSecurityException {
    mixin BasicExceptionCtors;
}

class NoSuchProviderException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateNotYetValidException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateExpiredException : Exception {
    mixin BasicExceptionCtors;
}

class SignatureException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateEncodingException : Exception {
    mixin BasicExceptionCtors;
}

class ParsingException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateParsingException : ParsingException {
    mixin BasicExceptionCtors;
}

class InvalidKeyException : Exception {
    mixin BasicExceptionCtors;
}

class KeyStoreException : Exception {
    mixin BasicExceptionCtors;
}

class UnrecoverableKeyException : Exception {
    mixin BasicExceptionCtors;
}

class KeyManagementException : Exception {
    mixin BasicExceptionCtors;
}

class IllegalThreadStateException : IllegalArgumentException {
    mixin BasicExceptionCtors;
}

class IllegalMonitorStateException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NestedRuntimeException : Exception {
    mixin BasicExceptionCtors;
}

class InvalidClassException : Exception {
    mixin BasicExceptionCtors;
}

class InvalidObjectException : Exception {
    mixin BasicExceptionCtors;
}

class ClassCastException : Exception {
    mixin BasicExceptionCtors;
}

class SystemException : Exception {
    mixin BasicExceptionCtors;
}

class ConfigurationException : Exception {
    mixin BasicExceptionCtors;
}


// ===================== Error =====================

class AssertionError : Error {
    mixin BasicExceptionCtors;
}

class LinkageError : Error {
    mixin BasicExceptionCtors;
}

class OutOfMemoryError : Error {
    mixin BasicExceptionCtors;
}

class ThreadDeath : Error {
    mixin BasicExceptionCtors;
}
