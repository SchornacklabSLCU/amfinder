(* CastANet - uI_Levels.ml *)

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

  let make_radio group str lvl =
    (* Container for the GtkRadioButton and its corresponding GtkLabel. *)
    let packing = (GPack.hbox ~packing:P.packing ())#pack ~expand:false in
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
    ) AmfLevel.all_flags ["Colonization"; "Myc structures"]
    
  let set_callback f =
    List.iter (fun (lvl, radio) ->
      let callback () = f lvl radio in
      ignore (radio#connect#toggled ~callback)
    ) radios
end
