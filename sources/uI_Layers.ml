(* CastANet - uI_Layers.ml *)

open Printf

type radio_ext = {
  r_radio : GButton.radio_tool_button;
  r_label : GMisc.label;
  r_image : GMisc.image;
}

module type RADIO = sig
  val table : GButton.toolbar
  val radios : (char * radio_ext) list
end 

module type PARAMS = sig
  val packing : GObj.widget -> unit
  val remove : GObj.widget -> unit
  val current : unit -> CLevel.t
  val radios : (CLevel.t * GButton.radio_button) list
end

module type S = sig
  val get_active : unit -> char
  val set_label : char -> int -> unit
  val set_callback : 
    (char -> 
      GButton.radio_tool_button -> GMisc.label -> GMisc.image -> unit) -> unit
end


module Make (P : PARAMS) : S = struct
  let add_item packing a_ref g_ref i chr =
    let active = !a_ref and group = !g_ref in
    let r_radio = GButton.radio_tool_button ~active ?group ~packing () in
    if active then (a_ref := false; g_ref := Some r_radio);
    let hbox = GPack.hbox ~spacing:2 ~packing:r_radio#set_icon_widget () in
    let packing = hbox#add in
    let r_image = GMisc.image ~width:24 ~packing () in
    let r_label = GMisc.label
      ~markup:"<small><tt>0000</tt></small>" ~packing () in
    let style = if chr = '*' then `RGBA else `GREY in
    r_image#set_pixbuf (CIcon.get chr style `SMALL);
    chr, {r_radio; r_label; r_image}

  let make_toolbox typ =
    let code_list = '*' :: CAnnot.char_list typ in
    let module T = struct
      let table = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:78 ~height:330 ()
      let active = ref true
      let group = ref None
      let packing = table#insert
      let radios = 
        UI_Helper.separator packing;
        UI_Helper.label packing "Layer";
        List.mapi (add_item packing active group) code_list
    end in (module T : RADIO)
    
  let toolboxes = List.map (fun typ -> typ, make_toolbox typ) CLevel.flags

  let current_widget = ref None

  let detach () =
    match !current_widget with
    | None -> ()
    | Some widget -> P.remove widget 

  let attach typ =
    detach ();
    let mdl = List.assoc typ toolboxes in
    let module T = (val mdl : RADIO) in
    let widget = T.table#coerce in
    P.packing widget;
    current_widget := Some widget
 
  let current_radios () =
    let toolbox = List.assoc (P.current ()) toolboxes in
    let open (val toolbox : RADIO) in radios

  let get_joker () = current_radios ()
    |> List.hd
    |> snd
  
  let get_layer c1 = current_radios ()
    |> List.find (fun (c2, _) -> c1 = c2)
    |> snd

  let get_active () = current_radios ()
    |> List.find (fun (_, t) -> t.r_radio#get_active)
    |> fst
  
  let is_active chr =
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ext.r_radio#get_active

  let set_image chr =
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ext.r_image#set_pixbuf

  let set_label chr num =
    let ext = if chr = '*' then get_joker () else get_layer chr in
    ksprintf ext.r_label#set_label "<small><tt>%04d</tt></small>" num
  
  let set_callback f =
    List.iter (fun (_, toolbox) ->
      let module T = (val toolbox : RADIO) in
      List.iter (fun (chr, ext) ->
        let callback () = f chr ext.r_radio ext.r_label ext.r_image in
        ignore (ext.r_radio#connect#toggled ~callback)
      ) T.radios
    ) toolboxes  
 
  let iter f =
    List.iter (fun (chr, r) -> 
      f chr r.r_radio r.r_label r.r_image) 
    (current_radios ()) 

  let _ =
    (* Initializes the annotation toolbar using the lightweight annotation style
     * `COLONIZATION, and initiates the callback function that updates the UI
     * according to the active radio button. *)
    attach `COLONIZATION;
    List.iter (fun (typ, radio) ->
      radio#connect#toggled ~callback:(fun () ->
        if radio#active then attach typ
      ); ()
    ) P.radios;
    (* Update the icon style when a GtkRadioToolButton is toggled. *)
    let callback chr radio _ icon =
      let style = if radio#get_active then `RGBA else `GREY in
      icon#set_pixbuf (CIcon.get chr style `SMALL)
    in set_callback callback
end
