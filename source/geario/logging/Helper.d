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

module geario.logging.Helper;

version(GEAR_DEBUG) {
    import geario.logging.ConsoleLogger;
} else {
    import geario.logging.Logger;
}


import core.runtime;
import core.stdc.stdlib;
import std.exception;

void catchAndLogException(E)(lazy E runer) @trusted nothrow
{
    try
    {
        runer();
    }
    catch (Exception e)
    {
        collectException(Warning(e.toString));
    }
    catch (Error e)
    {
        collectException(() { error(e.toString); rt_term(); }());
        exit(-1);
    }
}