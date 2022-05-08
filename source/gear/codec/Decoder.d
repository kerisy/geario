/*
 * Gear - A refined core library for writing reliable asynchronous applications with D programming language.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module gear.codec.Decoder;

import gear.buffer.Buffer;

/** 
 * 
 */
interface Decoder(DT)
{
    // -1 : Failed
    //  0 : Partial
    // >0 : Parsed length
    long Decode(ref Buffer buffer, ref DT message);
}
