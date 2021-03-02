(* AMFinder - ui/uILevels.ml
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

open Printf

module type PARAMS = sig
  val init_level : AmfLevel.level
  val packing : GObj.widget -> unit
end

module type S = sig
  val current : unit -> AmfLevel.level
  val set_current : AmfLevel.level -> unit
  val radios : (AmfLevel.level * GButton.radio_button) list 
  val set_callback : (AmfLevel.level -> GButton.radio_button -> unit) -> unit
end

module Make (P : PARAMS) : S = struct
  let curr = ref P.init_level
  let current () = !curr
  let set_current x = curr := x

  let make_radio group step text lvl =
    (* Container for the GtkRadioButton and its corresponding GtkLabel. 
    let packing = (GPack.hbox ~packing:P.packing ())#pack ~expand:false in*)
    (* Radio button without a label (will use a GtkLabel for that). *)
    let active = group = None in
    let r = GButton.radio_button ?group ~active ~packing:P.packing () in
    (* Removes the unpleasant focus square around the round button. *)
    r#misc#set_can_focus false;
    let markup = sprintf "<big><b>%s.</b> %s</big>" step text in
    ignore (GMisc.label ~markup ~packing:r#set_image ());
    (* Updates the annotation level upon activation. *)
    r#connect#toggled (fun () -> if r#active then curr := lvl);
    r

  let radios = 
    let group = ref None in
    List.map2 (fun lvl (step, text) ->
      let radio = make_radio !group step text lvl in
      if !group = None then group := Some radio#group;
      lvl, radio
    ) AmfLevel.all AmfLang.[en_stage_A, en_stage_A_label; 
                            en_stage_B, en_stage_B_label]
    
  let set_callback f =
    List.iter (fun (level, radio) ->
      let callback () = f level radio in
      ignore (radio#connect#toggled ~callback)
    ) radios
end
