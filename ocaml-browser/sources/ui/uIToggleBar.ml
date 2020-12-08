(* CastANet - uI_ToggleBar.ml *)

type toggle_bar = {
    tb_table : GPack.table;
    tb_items : (char * (GButton.toggle_button * GMisc.image)) list
}

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

    (* Add horizontal space between toggle buttons. *)
    let hspace = 134

    let add_item (table : GPack.table) left chr =
        let toggle = GButton.toggle_button
            ~relief:`NONE
            ~packing:(table#attach ~left ~top:0) () in
        toggle#misc#set_can_focus false;
        (* Toggle button icon. *)
        let image = GMisc.image
            ~width:48
            ~pixbuf:AmfIcon.(get chr Large Grayscale)
            ~packing:toggle#set_image () in
        (chr, (toggle, image))

    let toolboxes =
        List.map (fun level ->
            let categories = AmfLevel.to_header level in
            let tb_table = GPack.table
                ~rows:1
                ~columns:(List.length categories)
                ~col_spacings:hspace
                ~homogeneous:true () in
            let toggle_bar = {
                tb_table;
                tb_items = List.mapi (add_item tb_table) categories
            } in (level, toggle_bar)
        ) AmfLevel.[RootSegm; IRStruct]

    let current_widget = ref None
    let detach () = Option.iter P.remove !current_widget

    let attach level =
        detach ();
        let widget = (List.assoc level toolboxes).tb_table#coerce in
        P.packing widget;
        P.set_current level;
        current_widget := Some widget

    let iter_any level f =
        List.assoc level toolboxes
        |> (fun toggle_bar -> toggle_bar.tb_items)
        |> List.iter (fun (chr, (x, y)) -> f chr x y)

    let iter_current f = iter_any (P.current ()) f

    let iter_all f =
        List.iter (fun x -> iter_any x (f x)) AmfLevel.[RootSegm; IRStruct]

    let items ?(level = P.current ()) () =
        (List.assoc level toolboxes).tb_items

    let get ?level chr =
        List.assoc_opt (Char.uppercase_ascii chr) (items ?level ())

    let is_active = function
        (* Check activation of all toggle buttons. *)
        | '*' -> Some (List.for_all (fun (_, (tb, _)) -> tb#active) (items ()))
        (* Check activation of a single toggle button. *)
        | chr -> Option.map (fun x -> (fst x)#active) (get chr)

    let _ = (* initialization. *)
    (* Setting up expand/fill allows to centre the button box. *)
    attach AmfLevel.root_segmentation;
    List.iter (fun (level, radio) ->
        let callback () = if radio#active then attach level in
        ignore (radio#connect#toggled ~callback)
    ) P.radios

end

