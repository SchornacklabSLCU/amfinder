(* CastANet - cGUI_Levels.ml *)

open Printf

module type S = sig
  val current : unit -> CLevel.t
  val set_current : CLevel.t -> unit
  val radios : (CLevel.t * GButton.radio_button) list 
  val set_callback : (CLevel.t -> GButton.radio_button -> unit) -> unit
end


let make ~packing () =
  let module M = struct
    let curr = ref CLevel.lowest
    let current () = !curr
    let set_current x = curr := x

    let make_radio group str lvl =
      (* Container for the GtkRadioButton and its corresponding GtkLabel. *)
      let packing = (GPack.hbox ~packing ())#pack ~expand:false in
      (* Radio button without a label (will use a GtkLabel for that). *)
      let active = group = None in
      let r = GButton.radio_button ?group ~active ~packing () in
      (* Removes the unpleasant focus square around the round button. *)
      r#misc#set_can_focus false;
      let markup = sprintf "<big><b>%s</b></big>" str in
      ignore (GMisc.label ~markup ~packing ());
      (* Updates the annotation level upon activation. *)
      r#connect#toggled (fun () -> if r#active then curr := lvl);
      r

    let radios = 
      let group = ref None in
      List.map2 (fun lvl lbl ->
        let radio = make_radio !group lbl lvl in
        if !group = None then group := Some radio#group;
        lvl, radio
      ) CLevel.flags CLevel.strings
      
    let set_callback f =
      List.iter (fun (lvl, radio) ->
        let callback () = f lvl radio in
        ignore (radio#connect#toggled ~callback)
      ) radios
  end in (module M : S)
