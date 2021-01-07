(* AMFinder - amfColor.mli
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

(** Color management. *)

type red = float
type blue = float
type green = float
type alpha = float

val opacity : alpha
(** Alpha channel value used for annotations and predictions. *)

val parse_rgb : string -> red * green * blue
(** [parse_rgb "#rrggbbaa"] returns normalized floating-point values
  * corresponding to the red, green, and blue components of the input
  * color. *)

val parse_rgba : string -> red * green * blue * alpha
(** [parse_rgba "#rrggbbaa"] returns normalized floating-point values
  * corresponding to the red, green, blue, and alpha components of the input
  * color. *)

val parse_desaturate : string -> red * green * blue * alpha
(** [parse_desaturate "#rrggbbaa"] returns normalized floating-point values
  * corresponding to the closest grayscale value to color ["#rrggbbaa"].
  * Conversion relies on the standard luminosity formula
  * (i.e. [0.30 * r + 0.59 * g + 0.11 * b]). *)
