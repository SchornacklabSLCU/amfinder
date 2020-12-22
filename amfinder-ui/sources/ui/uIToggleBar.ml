(* AMFinder - ui/uIToggleBar.ml
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
        | chr -> match get chr with
            | None -> None (* can check other layer! *)
            | Some x -> Some (fst x)#active

    let _ = (* initialization. *)
    (* Setting up expand/fill allows to centre the button box. *)
    attach AmfLevel.root_segmentation;
    List.iter (fun (level, radio) ->
        let callback () = if radio#active then attach level in
        ignore (radio#connect#toggled ~callback)
    ) P.radios

end

