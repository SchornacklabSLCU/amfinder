(* AMFinder - ui/uIToggleBar.mli
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

(** UI auxiliary module dealing with annotation toggle buttons. *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
  
  val remove : GObj.widget -> unit
  
  val current : unit -> AmfLevel.level
  
  val set_current : AmfLevel.level -> unit
  
  val radios : (AmfLevel.level * GButton.radio_button) list
end


module type S = sig
    val is_active : char -> bool option
    (** Indicate whether the given annotation is active at the current level. *)

    val iter_all : (AmfLevel.level -> char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
    (** Iterate over all toggle buttons. *)

    val iter_current : (char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
    (** Iterate over toggle buttons at the current level. *)
end


module Make : PARAMS -> S
(** Generator. *)
