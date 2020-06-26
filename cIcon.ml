(* CastANet - caN_icon.ml *)

open CExt
open Printf

let dir = "data"

let build_file_list suf =
  List.map (fun chr ->
    let name = sprintf "%c%s" chr suf in
    (chr, Filename.concat dir name)
  ) CAnnot.code_list

let source n (c, s) = (c, GdkPixbuf.from_file_at_size ~width:n ~height:n s)
let sources n = List.map (source n)

module RGBA = struct
  let names = build_file_list "_rgba.png"
  let large_set = sources 48 names
  let small_set = sources 24 names
end

module Grey = struct
  let names = build_file_list "_grey.png"
  let large_set = sources 48 names
  let small_set = sources 24 names
end

module Grad = struct
  let names = build_file_list "_grad.png"
  let large_set = sources 48 names
  let small_set = sources 24 names
end

module Special = struct
  let any_rgba = ('*', Filename.concat dir "Any_rgba.png")
  let any_grey = ('*', Filename.concat dir "Any_grey.png")
  let large_any_rgba = snd (source 48 any_rgba)
  let small_any_rgba = snd (source 24 any_rgba)
  let large_any_grey = snd (source 48 any_grey)
  let small_any_grey = snd (source 24 any_grey)
end

type icon_type = [ `RGBA | `GREY ]
type icon_size = [ `LARGE | `SMALL ]

let get ?(grad = true) chr i_type i_size =
  assert (String.contains CAnnot.codes chr);
  let is_grad = grad && CAnnot.annotation_type () = `GRADIENT in
  let set = match i_type, i_size with
    | `RGBA, `LARGE -> if is_grad then Grad.large_set else RGBA.large_set
    | `RGBA, `SMALL -> if is_grad then Grad.small_set else RGBA.small_set
    | `GREY, `LARGE -> Grey.large_set
    | `GREY, `SMALL -> Grey.small_set
  in List.assoc chr set

let get_special i_type i_size =
  let open Special in
  match i_type, i_size with
  | `RGBA, `LARGE -> large_any_rgba
  | `RGBA, `SMALL -> small_any_rgba
  | `GREY, `LARGE -> large_any_grey
  | `GREY, `SMALL -> small_any_grey
