(* CastANet - cIcon.ml *)

open Printf

type icon_type = [ `RGBA | `GREY ]
type icon_size = [ `LARGE | `SMALL ]

let dir = "data"

let build_path_list suf =
  let path chr = Filename.concat dir (sprintf "%c_%s.png" chr suf) in
  List.map (fun chr -> chr, path chr) CAnnot.code_list

module Source = struct
  let pixbuf n (c, s) = (c, GdkPixbuf.from_file_at_size ~width:n ~height:n s)
  let pixbuf_list n = List.map (pixbuf n)
  let import f s = f (if s = `SMALL then 24 else 48)
  let load = import pixbuf
  let load_multiple = import pixbuf_list
end

module type IconSet = sig
  val large : (char * GdkPixbuf.pixbuf) list
  val small : (char * GdkPixbuf.pixbuf) list
end

let icon_set suf =
  let module M = struct
    let names = build_path_list suf
    let large = Source.load_multiple `LARGE names
    let small = Source.load_multiple `SMALL names
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
  let make str =
    let ico = make str in
    Source.(snd (load `SMALL ico), snd (load `LARGE ico))
  let rgba = make "rgba"
  let grey = make "grey"
end

let get_joker sty typ =
  let choose = if typ = `SMALL then fst else snd in
  choose Joker.(if sty = `RGBA then rgba else grey)

let get ?grad chr typ fmt =
  if chr = '*' then get_joker typ fmt
  else List.assoc chr (Select.size fmt (Select.style ?grad typ)) 
