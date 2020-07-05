(* CastANet - cExt.ml *)

module File = struct
  let read ?(binary = true) ?(trim = true) str = 
    let ich = (if binary then open_in_bin else open_in) str in
    let len = in_channel_length ich in
    let buf = Buffer.create len in
    Buffer.add_channel buf ich len;
    close_in ich;
    let str = Buffer.contents buf in
    if trim then String.trim str else str
end


module Matrix = struct
  type 'a t = 'a array array
  let get t r c = t.(r).(c)
  let get_opt t r c = try Some t.(r).(c) with _ -> None
  let init nr nc f = Array.(init nr (fun r -> init nc (f r)))
  let map f = Array.(map (map f))
  let mapi f = Array.(mapi (fun r -> mapi (f r)))
  let iter f = Array.(iter (iter f))
  let iteri f = Array.(iteri (fun r -> iteri (f r)))
end


module Split = struct
  let lines = String.split_on_char '\n'
  let tabs = String.split_on_char '\t'
  let colons = String.split_on_char ':'
  let semicolons = String.split_on_char ';'
  let commas = String.split_on_char ','
  let spaces = String.split_on_char ' '
end


module Maybe = struct
  type 'a t = V of 'a | E of exn
  let from_value x = V x
  let from_exception e = E e
  let from_option = function None -> E Not_found | Some x -> V x
  let to_option = function V x -> Some x | _ -> None
  let is_value = function V _ -> true | _ -> false
  let is_exception = function E _ -> true | _ -> false
  let eval f x = try V (f x) with e -> E e
  let iter f = function V x -> f x | _ -> ()
  let map f = function V x -> eval f x | E e -> E e
  let fix g = function E e -> eval g e | value -> value
end


module Color = struct
  let html_to_int s =
    Scanf.sscanf s "#%02x%02x%02x" (fun r g b -> r, g, b)

  let html_to_int16 s = 
    let r, g, b = html_to_int s in 
    r lsl 8, g lsl 8, b lsl 8

  let html_to_float =
    let f x = float x /. 255.0 in
    fun s -> let r, g, b = html_to_int s in f r, f g, f b

  let float_to_int =
    let f x = truncate (x *. 255.0) in
    fun r g b -> (f r, f g, f b)

  let float_to_html r g b =
    let r, g, b = float_to_int r g b in
    Printf.sprintf "#%02x%02x%02x" r g b
end


module Image = struct
  let crop_square ~src_x ~src_y ~edge:e pix =
    let dest = GdkPixbuf.create ~width:e ~height:e () in
    GdkPixbuf.copy_area ~dest ~src_x ~src_y pix;
    dest
      
  let resize ?(interp = `NEAREST) ~edge:e pix =
    let open GdkPixbuf in
    let scale_x = float e /. (float (get_width pix))
    and scale_y = float e /. (float (get_height pix)) in
    let dest = create ~width:e ~height:e () in
    scale ~dest ~scale_x ~scale_y ~interp pix;
    dest
end


module Draw = struct
  let square ?(clr = "#cc0000") ?(a = 1.0) edge =
    let open Cairo in
    let surface = Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = create surface in
    set_antialias t ANTIALIAS_SUBPIXEL;
    let r, g, b = Color.html_to_float clr in
    set_source_rgba t r g b a;
    let edge = float edge in
    rectangle t 0.0 0.0 ~w:edge ~h:edge;
    fill t;
    stroke t;
    surface
end

let time f x =
  let t_1 = Unix.gettimeofday () in
  let res = f x in
  let t_2 = Unix.gettimeofday () in
  CLog.info "elapsed time: %.1f s" (t_2 -. t_1);
  res


module Memoize = struct
  let flag = ref 0

  type 'a t = {
    mutable flag : int;
    mutable data : [`F of (unit -> 'a) | `R of 'a];
  }

  let exec f mem = let x = f () in mem.data <- `R x; x

  let create lbl f =
    let mem = { flag = 0; data = `F f } in
    (fun () -> match mem.data with
      | `F f -> exec f mem
      | `R x -> 
        if !flag > mem.flag then (
          CLog.info "Discarding memoized data for '%s'" lbl;
          let x = exec f mem in 
          mem.flag <- mem.flag + 1;
          x
        ) else x
    )

  let forget () = incr flag
end
