(* AMFinder - amfLog.mli
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

(** Logging functions. *)

val info : ('a, unit, string, string, string, unit) format6 -> 'a
(** Prints a piece of information to [stdout]. *)

val info_debug : ('a, unit, string, string, string, unit) format6 -> 'a
(** Same, but only prints when [_DEBUG_] is set to [true]. *)

val warning : ('a, unit, string, string, string, unit) format6 -> 'a
(** Prints a warning message to [stderr]. *)

val error : ?code:int -> ('a, unit, string, string, string, 'b) format6 -> 'a
(** Prints an error message to [stderr] and terminates with the given code. *)

val usage : unit -> 'a
(** Specialized [error] function with application message. *)
