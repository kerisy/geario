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

module gear.codec.Decoder;

import nbuff;

/** 
 * 
 */
interface Decoder(DT)
{
    // -1 : Failed
    //  0 : Partial
    // >0 : Parsed length
    long Decode(ref Nbuff buffer, ref DT message);
}
