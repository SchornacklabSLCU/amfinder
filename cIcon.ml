(* CastANet - cIcon.ml *)

(* Icon sources. Load icons as pixbufs of 24 (small) or 48 (large) pixels. *)
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

(* Icon set builder. Retrieve paths to icon files and load all icon flavours. *)
module Build = struct
  let path_list suf =
    let make_pair chr = Printf.sprintf "%c_%s.png" chr suf
      |> Filename.concat CCore.data_dir
      |> (fun path -> chr, path)
    in List.map make_pair CAnnot.code_list

  let icon_set suf =
    let names = path_list suf in
    let module M = struct
      let large = Source.load_multiple `LARGE names
      let small = Source.load_multiple `SMALL names
    end in (module M : IconSet)
end

let m_rgba = Build.icon_set "rgba" (* Active toggle buttons with binary data. *)
let m_grad = Build.icon_set "grad" (* Same, but with confidence values.       *)
let m_grey = Build.icon_set "grey" (* Inactive toggle buttons.                *)

(* Joker icon for display any annotation (irrespective of their type). *)
module Joker = struct
  let make suf =
    let ico = Printf.sprintf "Joker_%s.png" suf
      |> Filename.concat CCore.data_dir
      |> (fun path -> '*', path)
    in Source.(snd (load `SMALL ico), snd (load `LARGE ico))
  let rgba = make "rgba"
  let grey = make "grey"
end

(* Icon selection, based on size (small/large) and style (grey/rgba). *)
module Select = struct
  let size typ ico = 
    let open (val ico : IconSet) in
    if typ = `SMALL then small else large

  let style ?(grad = true) = function
    | `GREY -> m_grey
    | `RGBA -> if grad && CAnnot.is_gradient () then m_grad else m_rgba
end

module Get = struct
  let joker sty typ = Joker.(if sty = `RGBA then rgba else grey)
    |> if typ = `SMALL then fst else snd

  let standard ?grad chr sty typ = Select.style ?grad sty
    |> Select.size typ
    |> List.assoc chr 
end

let get ?grad = function '*' -> Get.joker | chr -> Get.standard ?grad chr
