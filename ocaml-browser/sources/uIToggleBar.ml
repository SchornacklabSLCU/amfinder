(* CastANet - uI_ToggleBar.ml *)

type toggle_ext = {
  t_toggle : GButton.toggle_button;
  t_image : GMisc.image;
}

module type TOGGLE = sig
  val table : GPack.table
  val toggles : (char * toggle_ext) array
end

module type S = sig
  val is_active : char -> bool option
  val set_status : (CLevel.t * CMask.layered_mask) list -> unit
  val is_locked : unit -> bool
end


module type PARAMS = sig
  val packing : GObj.widget -> unit
  val remove : GObj.widget -> unit
  val current : unit -> CLevel.t
  val set_current : CLevel.t -> unit
  val radios : (CLevel.t * GButton.radio_button) list
end


module Make (P : PARAMS) : S = struct

  (* Values here ensure that new buttons appear between existing ones when
   * the user switches between the different annotation levels. *)
  let get_col_spacing = function
    | `COLONIZATION -> 134
    | `ARB_VESICLES -> 68
    | `ALL_FEATURES -> 2

  let set_icon image button rgba grey () =
    image#set_pixbuf (if button#active then rgba else grey)  

  let add_item (table : GPack.table) i chr =
    let packing = table#attach ~left:i ~top:0 in
    let t_toggle = GButton.toggle_button ~relief:`NONE ~packing () in
    let t_image = GMisc.image ~width:48 ~packing:t_toggle#set_image () in
    t_image#set_pixbuf (CIcon.get chr `GREY `LARGE);
    chr, {t_toggle; t_image}

  let make_toolbox typ =
    let code_list = CAnnot.char_list typ in
    let module T = struct
      let table = GPack.table
        ~rows:1 ~columns:(List.length code_list)
        ~col_spacings:(get_col_spacing typ)
        ~homogeneous:true ()
      let toggles = Array.of_list (List.mapi (add_item table) code_list)
    end in (module T : TOGGLE)

  let toolboxes =
    List.map (fun typ ->
      typ, make_toolbox typ
    ) CLevel.all_flags

  let iter f =
    List.iter (fun (typ, mdl) ->
      let module T = (val mdl : TOGGLE) in
      Array.iter (fun (chr, {t_toggle; t_image}) -> 
        f typ chr t_toggle t_image
      ) T.toggles
    ) toolboxes

  let map f =
    List.map (fun (typ, mdl) ->
      let module T = (val mdl : TOGGLE) in
      Array.map (fun (chr, {t_toggle; t_image}) ->
        f typ chr t_toggle t_image
      ) T.toggles
    ) toolboxes

  let current_widget = ref None

  let detach () =
    match !current_widget with
    | None -> ()
    | Some widget -> P.remove widget

  let attach typ =
    detach ();
    let mdl = List.assoc typ toolboxes in
    let module T = (val mdl : TOGGLE) in
    let widget = T.table#coerce in
    P.packing widget;
    P.set_current typ;
    current_widget := Some widget

  let current_toggles () =
    let current_toolbox = List.assoc (P.current ()) toolboxes in
    let module T = (val current_toolbox : TOGGLE) in
    T.toggles

  let get ?level chr =
    let lvl = match level with
      | None -> P.current ()
      | Some lvl -> lvl in
    let toolbox = List.assoc lvl toolboxes in
    let module T = (val toolbox : TOGGLE) in
    List.assoc_opt (Char.uppercase_ascii chr) (Array.to_list T.toggles)

  let toggle_lock = ref false

  let lock () = toggle_lock := true
  let unlock () = toggle_lock := false
  let is_locked () = !toggle_lock

  let is_active chr =
    match get chr with
    | None -> None
    | Some ext -> Some ext.t_toggle#active

  let revert_all lvl =
    let toolbox = List.assoc lvl toolboxes in
    let module T = (val toolbox : TOGGLE) in  
    Array.iter (fun (chr, ext) ->
      ext.t_toggle#set_active false;
      ext.t_image#set_pixbuf (CIcon.get chr `GREY `LARGE);
    ) T.toggles

  let set_status t =
    toggle_lock := true;
    List.iter (fun (lvl, mask) ->
      revert_all lvl;
      let user = mask#get `USER
      and hold = mask#get `HOLD
      and lock = mask#get `LOCK in
      let toolbox = List.assoc lvl toolboxes in
      let module T = (val toolbox : TOGGLE) in
      let assoc_table = Array.to_list T.toggles in
      let apply_settings ~layer ~status ~style ?alt_style () =
        String.iter (fun chr ->
          let ext = List.assoc chr assoc_table in
          ext.t_toggle#set_active status;
          let style = match lvl = P.current () with
            | true -> style
            | false -> Option.value alt_style ~default:style in
          ext.t_image#set_pixbuf (CIcon.get chr style `LARGE);
        ) layer in
      apply_settings ~layer:user ~status:true ~style:`RGBA ();
      apply_settings ~layer:hold ~status:true ~style:`RGBA_LOCKED ();
      apply_settings ~layer:lock ~status:false ~style:`GREY ~alt_style:`GREY_LOCKED ()
    ) t;
    toggle_lock := false

  let _ = (* initialization. *)
    (* Setting up expand/fill allows to centre the button box. *)
    attach `COLONIZATION;
    List.iter (fun (typ, radio) ->
      let callback () = if radio#active then attach typ in
      ignore (radio#connect#toggled ~callback)
    ) P.radios
end

