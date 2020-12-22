(* AMFinder - amfMemoize.mli
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

open Cairo

(** Memoization. *)

val create : ('a -> 'b) -> 'a -> 'b
(** [create f] returns a memoized version of function [f]. *)


(** {2 Memoized Cairo functions} *)

val cursor : AmfSurface.pixels -> Surface.t
(** Square with a thick red stroke. *)

val dashed_square : AmfSurface.pixels -> Surface.t
(** Rounded square with a dashed stroke. *)

val locked_square : AmfSurface.pixels -> Surface.t
(** Rounded square with a lock. *)

val empty_square : AmfSurface.pixels -> Surface.t
(** Empty square. *)

val palette : int -> AmfSurface.pixels -> Surface.t
(** Circle filled with color from a given palette. *)

val layer : AmfLevel.level -> char -> AmfSurface.pixels -> Surface.t
(** Rounded square with a symbol and filled with a specific color. *)
