(* CastANet - cIcon.ml *)

open Printf

type icon_type = [ `RGBA | `GREY ]
type icon_size = [ `LARGE | `SMALL ]

let dir = "data"

let build_path_list suf =
  let path chr = Filename.concat dir (sprintf "%c_%s.png" chr suf) in
  List.map (fun chr -> chr, path chr) CAnnot.code_list

module Source = struct
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

let icon_set suf =
  let module M = struct
    let names = build_path_list suf
    let large = Source.get_multiple `LARGE names
    let small = Source.get_multiple `SMALL names
  end in (module M : IconSet)

let m_rgba = icon_set "rgba" (* Active toggle buttons.   *)
let m_grad = icon_set "grad" (* Active with confidence.  *)
let m_grey = icon_set "grey" (* Inactive toggle buttons. *)

module Select = struct
  let size typ ico = 
    let open (val ico : IconSet) in
    if typ = `SMALL then small else large
  let style ?(grad = true) = function
    | `GREY -> m_grey
    | `RGBA -> if grad && CAnnot.is_gradient () then m_grad else m_rgba
end
 
module Joker = struct
  let make suf = "*", Filename.concat dir (sprintf "Joker_%s.png" suf) 
  let rgba = make "rgba"
  let grey = make "grey"
  let large_rgba = snd (Source.get `LARGE rgba)
  let small_rgba = snd (Source.get `SMALL rgba)
  let large_grey = snd (Source.get `LARGE grey)
  let small_grey = snd (Source.get `SMALL grey)
end

let get_joker typ = function
  | `SMALL -> Joker.(if typ = `RGBA then small_rgba else small_grey)
  | `LARGE -> Joker.(if typ = `RGBA then large_rgba else large_grey)

let get ?grad chr typ fmt =
  if chr = '*' then get_joker typ fmt
  else List.assoc chr (Select.size fmt (Select.style ?grad typ)) 
