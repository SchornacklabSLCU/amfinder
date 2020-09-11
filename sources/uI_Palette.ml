(* uI_Palette.ml *)

open Printf

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type S = sig
  val toolbar : GButton.toolbar
  val current : unit -> CIcon.palette
  val viridis : GButton.radio_tool_button * GMisc.image
  val cividis : GButton.radio_tool_button * GMisc.image
  val plasma : GButton.radio_tool_button * GMisc.image
  val best : GButton.tool_button
  val threshold : GButton.tool_button
end

module Make (P : PARAMS) : S = struct
  let current_palette = ref `VIRIDIS
  let current () = !current_palette

  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:78 ~height:205
    ~packing:P.packing ()

  let packing = toolbar#insert

  let _ = UI_Helper.separator packing; UI_Helper.label packing "Predictions"

  let radio_tool_button ?(active = false) ?group ~label typ =
    let radio = GButton.radio_tool_button ~active ?group ~packing () in
    let hbox = GPack.hbox ~packing:radio#set_icon_widget () in
    let image = GMisc.image ~width:20 ~packing:(hbox#pack ~expand:false) () in
    ignore (GMisc.label ~markup:(sprintf "<span size='x-small'>%s</span>" label)
      ~packing:(hbox#pack ~fill:true) ());
    image#set_pixbuf (CIcon.get_palette typ `SMALL);
    radio, image

  let viridis = radio_tool_button ~active:true ~label:"Viridis" `VIRIDIS

  let group = fst viridis

  let cividis = radio_tool_button ~group  ~label:"Cividis" `CIVIDIS

  let plasma = radio_tool_button ~group  ~label:"Plasma" `PLASMA

  let labelled_button label =
    let btn = GButton.tool_button ~packing () in
    ignore (GMisc.label ~markup:(sprintf "<small>%s</small>" label)
      ~packing:btn#set_icon_widget ());
    btn

  let best = labelled_button "Best"
  let threshold = labelled_button "Threshold"
end
