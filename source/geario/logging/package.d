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

module geario.logging;

version(GEAR_DEBUG) {
    public import geario.logging.ConsoleLogger;
} else {
    public import geario.logging.Logger;
}

public import geario.logging.Helper;
