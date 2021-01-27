(* AMFinder - amfPar.mli
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

(** Command-line settings. *)

val edge : int ref
(** Edge size, in pixels. *)

val print_large_maps : bool ref
(** Indicate whether amfbrowser prints large maps. *)

val path : string option ref
(** Deprecated? *)

val threshold : float ref
(** Annotation probability threshold. *)

val verbose : unit -> bool
(** [verbose ()] indicates whether the application runs in verbose mode.
  * It is recommended to switch on this mode for debugging. *)

val initialize : unit -> unit 
(** [initialize ()] reads command-line arguments. *)
