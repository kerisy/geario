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

module gear.codec.Encoder;

import nbuff;

/** 
 * 
 */
interface Encoder(ET)
{
    NbuffChunk Encode(ET message);
}
