(* CastANet - caN_icon.ml *)

open CExt
open Printf

type icon_type = [ `RGBA | `GREY ]
type icon_size = [ `LARGE | `SMALL ]

let dir = "data"

let build_path_list suf =
  let path chr = Filename.concat dir (sprintf "%c%s" chr suf) in
  List.map (fun chr -> chr, path chr) CAnnot.code_list

module Src = struct
  let import n (c, s) = (c, GdkPixbuf.from_file_at_size ~width:n ~height:n s)
  let import_multiple n = List.map (import n)
  let get_any f = function `SMALL -> f 24 | `LARGE -> f 48
  let get = get_any import
  let get_multiple = get_any import_multiple
end

module type IconSet = sig
  val large : (char * GdkPixbuf.pixbuf) list
  val small : (char * GdkPixbuf.pixbuf) list
end

let generator suf =
  let module M = struct
    let names = build_path_list suf
    let large = Src.get_multiple `LARGE names
    let small = Src.get_multiple `SMALL names
  end in (module M : IconSet)

let m_rgba = generator "_rgba" (* Active toggle buttons.   *)
let m_grad = generator "_grad" (* Active with confidence.  *)
let m_grey = generator "_grey" (* Inactive toggle buttons. *)

let get_by_size typ ico = 
  let open (val ico : IconSet) in
  match typ with `SMALL -> small | `LARGE -> large

let get_by_type ?(grad = true) = function
  | `GREY -> m_grey
  | `RGBA -> if grad && CAnnot.is_gradient () then m_grad else m_rgba

let get ?grad chr typ fmt =
  get_by_type ?grad typ
  |> get_by_size fmt
  |> List.assoc chr
  
module Special = struct
  let rgba = ('*', Filename.concat dir "Any_rgba.png")
  let grey = ('*', Filename.concat dir "Any_grey.png")
  let large_rgba = snd (Src.get `LARGE rgba)
  let small_rgba = snd (Src.get `SMALL rgba)
  let large_grey = snd (Src.get `LARGE grey)
  let small_grey = snd (Src.get `SMALL grey)
end

let get_special typ = function
  | `SMALL -> Special.(if typ = `RGBA then small_rgba else small_grey)
  | `LARGE -> Special.(if typ = `RGBA then large_rgba else large_grey)
