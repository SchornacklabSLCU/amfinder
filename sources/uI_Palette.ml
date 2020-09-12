(* uI_Palette.ml *)

open CExt
open Scanf
open Printf

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type S = sig
  val ids : unit -> string list
  val colors : id:string -> string array option
  val current : unit -> string
  val set_current : id:string -> unit
  val toolbar : GButton.toolbar
  val palette : GButton.tool_button
end

type palette = string array

let folder = "data/palettes"
let palette_db = ref []

let validate_color ?(default = "#ffffffff") s =
  ksscanf s (fun _ _ -> default) "#%02x%02x%02x" 
    (sprintf "#%02x%02x%02xcc")

let load () =
  Array.fold_left (fun pal elt ->
    let path = Filename.concat folder elt in
    if Filename.check_suffix path ".palette" then (
      let base = Filename.remove_extension elt in
        let colors = Ext_File.read path
          |> String.split_on_char '\n'
          |> List.map validate_color
          |> Array.of_list
        in (base, colors) :: pal
    ) else pal
  ) [] (Sys.readdir folder)


module Make (P : PARAMS) : S = struct

  let palette_db = ref (load ())
  let curr = ref (fst (List.hd !palette_db))
  
  let ids () = fst (List.split !palette_db)
  let colors ~id = List.assoc_opt id !palette_db

  let current () = !curr
  let set_current ~id =
    if List.mem_assoc id !palette_db then curr := id
    else CLog.warning "%s is not a valid palette identifier" id

  let toolbar = GButton.toolbar
    ~orientation:`VERTICAL
    ~style:`ICONS
    ~width:78 ~height:195
    ~packing:P.packing ()

  let packing = toolbar#insert

  let _ =
    UI_Helper.separator packing;
    UI_Helper.label packing "Predictions"

   

  let palette =
    let button = GButton.tool_button ~packing () in
    let hbox = GPack.hbox ~packing:button#set_icon_widget () in
    let image = GMisc.image ~width:20 ~packing:(hbox#pack ~expand:false) () in
    image#set_pixbuf (CIcon.get_palette `PLASMA `SMALL);
    ignore (GMisc.label 
      ~markup:"<span size='x-small'>Palette</span>"
      ~packing:(hbox#pack ~fill:true) ());
    button
end
