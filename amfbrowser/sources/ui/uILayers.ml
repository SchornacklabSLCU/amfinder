(* AMFinder - ui/uILayers.ml
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


type radio_ext = {
  r_radio : GButton.radio_tool_button;
  r_label : GMisc.label;
  r_image : GMisc.image;
}


module type RADIO = sig
  val toolbar : GButton.toolbar
  val radios : (char * radio_ext) list
end 


module type PARAMS = sig
  val packing : GObj.widget -> unit
  val remove : GObj.widget -> unit
  val current : unit -> AmfLevel.level
  val radios : (AmfLevel.level * GButton.radio_button) list
end


module type S = sig
  val current : unit -> char
  val set_label : char -> int -> unit
  val set_callback : 
    (char -> 
      GButton.radio_tool_button -> GMisc.label -> GMisc.image -> unit) -> unit
end



module Toolbox = struct

    let add_item packing a_ref g_ref i chr =
        let active = !a_ref and group = !g_ref in
        let r_radio = GButton.radio_tool_button ~active ?group ~packing () in
        if active then (a_ref := false; g_ref := Some r_radio);
        let hbox = GPack.hbox ~spacing:2 ~packing:r_radio#set_icon_widget () in
        let r_image = GMisc.image ~width:24 ~packing:hbox#add ()
        and r_label = GMisc.label
            ~markup:(if chr = '*' then (sprintf "<small>%s</small>" AmfLang.en_overlay)
                     else "<small><tt>000000</tt></small>")
            ~packing:hbox#add () in
        let style = chr = '*' in
        r_image#set_pixbuf (AmfRes.get (`CHAR (chr, style)) 24);
        chr, {r_radio; r_label; r_image}

    let make level =
        let code_list = '*' :: AmfLevel.to_header level in
        let module T = struct
            let toolbar = GButton.toolbar
                ~orientation:`VERTICAL
                ~style:`ICONS
                ~width:92 ~height:225 ()
            let active = ref true
            let group = ref None
            let packing = toolbar#insert
            let radios = 
                UIHelper.separator packing;
                UIHelper.label packing (sprintf "<b><small>%s</small></b>" AmfLang.en_layer);
                List.mapi (add_item packing active group) code_list
        end in (module T : RADIO)

end



module Make (P : PARAMS) : S = struct
    
    let toolboxes = 
        let make level = level, Toolbox.make level in
        List.map make AmfLevel.all

    let current_widget = ref None

    let detach () = Option.iter (fun widget -> P.remove widget) !current_widget

    let attach level =
        detach ();
        let radio = List.assoc level toolboxes in
        let module T = (val radio : RADIO) in
        let widget = T.toolbar#coerce in
        P.packing widget;
        current_widget := Some widget
 
    (* Returns radio buttons active at the current level. *)
    let current_level_radios () =
        let level = P.current () in
        let open (val (List.assoc level toolboxes) : RADIO) in
        radios

    (* Extracts a radio button from an association list. *)
    let get_radio_ext x = current_level_radios ()
        |> List.find (fun (y, _) -> x = y)
        |> snd

    (* Returns the "joker" radio button. *)
    let get_joker () = get_radio_ext '*'

    let current () = current_level_radios ()
        |> List.find (fun x -> (snd x).r_radio#get_active)
        |> fst
  
    let is_active chr = (get_radio_ext chr).r_radio#get_active

    let set_image chr = (get_radio_ext chr).r_image#set_pixbuf

    let set_label chr num =
        ksprintf (get_radio_ext chr).r_label#set_label 
            "<small><tt>%06d</tt></small>" num
  
    let set_callback f =
        List.iter (fun (level, radio) ->
            let module T = (val radio : RADIO) in
            List.iter (fun (chr, {r_radio; r_label; r_image}) ->
                let callback () = f chr r_radio r_label r_image in
                ignore (r_radio#connect#after#toggled ~callback)
            ) T.radios
    ) toolboxes  
 
    let iter f =
        List.iter (fun (chr, r) -> 
            f chr r.r_radio r.r_label r.r_image
        ) (current_level_radios ()) 

    let _ =
        attach AmfLevel.col;
        List.iter (fun (level, radio) ->
            let callback () = if radio#active then attach level in
            ignore (radio#connect#toggled ~callback)
        ) P.radios;
        let callback chr radio _ icon =
            let style = radio#get_active in
            icon#set_pixbuf (AmfRes.get (`CHAR (chr, style)) 24)
        in set_callback callback
end
