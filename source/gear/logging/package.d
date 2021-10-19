/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.logging;

version(GEAR_DEBUG) {
    public import gear.logging.ConsoleLogger;
} else {
    public import gear.logging.Logger;
}

public import gear.logging.Helper;
