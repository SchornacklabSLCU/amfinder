(* AMFinder - ui/uILevels.mli
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

(** UI auxiliary module dealing with annotation levels. *)

module type PARAMS = sig
  val init_level : AmfLevel.level
  val packing : GObj.widget -> unit
end

module type S = sig
  val current : unit -> AmfLevel.level
  (** Returns the active annotation level. *)
  
  val set_current : AmfLevel.level -> unit
  (** Changes the active annotation level. *)
  
  val radios : (AmfLevel.level * GButton.radio_button) list 
  (** Radio buttons corresponding to the different annotation types. *)

  val set_callback : (AmfLevel.level -> GButton.radio_button -> unit) -> unit
  (** Applies a callback function to all radio buttons. *)
end

module Make : PARAMS -> S
(** Generator. *)
