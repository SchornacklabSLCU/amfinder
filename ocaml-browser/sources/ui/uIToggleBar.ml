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
    val iter_all : (AmfLevel.level -> char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
    val iter_current : (char -> GButton.toggle_button -> GMisc.image -> unit) -> unit
end


module type PARAMS = sig
    val packing : GObj.widget -> unit
    val remove : GObj.widget -> unit
    val current : unit -> AmfLevel.level
    val set_current : AmfLevel.level -> unit
    val radios : (AmfLevel.level * GButton.radio_button) list
end


module Make (P : PARAMS) : S = struct

    (* Values here ensure that new buttons appear between existing ones when
    * the user switches between the different annotation levels. *)
    let get_col_spacing = function
        | AmfLevel.COLONIZATION -> 134
        | AmfLevel.MYC_STRUCTURES -> 2

    let add_item (table : GPack.table) i chr =
        let packing = table#attach ~left:i ~top:0 in
        let t_toggle = GButton.toggle_button ~relief:`NONE ~packing () in
        t_toggle#misc#set_can_focus false;
        let t_image = GMisc.image ~width:48 ~packing:t_toggle#set_image () in
        t_image#set_pixbuf (AmfIcon.get chr `GREY `LARGE);
        chr, {t_toggle; t_image}

    let make_toolbox typ =
        let code_list = AmfLevel.to_header typ in
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
        ) AmfLevel.all_flags

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

    let iter_current f =
        let current_toolbox = List.assoc (P.current ()) toolboxes in
        let module T = (val current_toolbox : TOGGLE) in
        Array.iter (fun (chr, ext) ->
            f chr ext.t_toggle ext.t_image
        ) T.toggles

    let iter_all f =
        List.iter (fun level ->
            let toolbox = List.assoc level toolboxes in
            let module T = (val toolbox : TOGGLE) in
            Array.iter (fun (chr, ext) ->
                f level chr ext.t_toggle ext.t_image
            ) T.toggles
        ) AmfLevel.all_flags

    let get ?level chr =
        let lvl = match level with
            | None -> P.current ()
            | Some lvl -> lvl in
        let toolbox = List.assoc lvl toolboxes in
        let module T = (val toolbox : TOGGLE) in
        List.assoc_opt (Char.uppercase_ascii chr) (Array.to_list T.toggles)

    let is_active chr =
        match get chr with
        | None -> None
        | Some ext -> Some ext.t_toggle#active

    let _ = (* initialization. *)
    (* Setting up expand/fill allows to centre the button box. *)
    attach AmfLevel.COLONIZATION;
    List.iter (fun (typ, radio) ->
        let callback () = if radio#active then attach typ in
        ignore (radio#connect#toggled ~callback)
    ) P.radios

end

