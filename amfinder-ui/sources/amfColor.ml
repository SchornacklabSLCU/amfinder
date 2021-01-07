(* AMFinder - amfColor.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

open Scanf
open Printf

type red = float
type blue = float
type green = float
type alpha = float

let opacity = float 0xB0 /. 255.0

let rgb_from_name = function
    | "cyan"    -> "#00ffff"
    | "green"   -> "#00ff00"
    | "white"   -> "#ffffff"
    | "black"   -> "#000000"
    | "yellow"  -> "#ffff00"
    | "magenta" -> "#ff00ff"
    | other     -> other

let rgba_from_name raw_color = 
    let color = rgb_from_name raw_color in
    if color = raw_color then color 
    else (* was a name *) color ^ "FF"

let normalize n = max 0.0 (min 1.0 (float n /. 255.0))

let parse_rgb s =
    assert (String.length s >= 7);
    sscanf (rgb_from_name s) "#%02x%02x%02x"
        (fun r g b -> normalize r, normalize g, normalize b)

let parse_rgba s =
    assert (String.length s >= 9);
    sscanf (rgba_from_name s) "#%02x%02x%02x%02x" 
        (fun r g b a -> normalize r, normalize g, normalize b, normalize a)

let parse_desaturate s =
    let r, g, b, a = match String.length s with
        | 7 -> let r, g, b = parse_rgb s in (r, g, b, 1.0)
        | 9 -> parse_rgba s
        | _ -> AmfLog.warning "Invalid color %s" s; (1.0, 1.0, 1.0, 1.0)
    in
    let g = max 0.0 (min 1.0 (r *. 0.30 +. g *. 0.59 +. b *. 0.11)) in
    (g, g, g, a)
