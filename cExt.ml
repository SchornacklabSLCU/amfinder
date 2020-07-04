(* CastANet - cExtlib.ml *)

open Scanf
open Printf

let read_file ?(trim = true) str = 
  let ich = open_in_bin str in
  let len = in_channel_length ich in
  let buf = Buffer.create len in
  Buffer.add_channel buf ich len;
  close_in ich;
  let str = Buffer.contents buf in
  if trim then String.trim str else str

let tagger_string_fold_left f ini s =
  let len = String.length s in
  let rec loop i res =
    if i < len then
      let elt = f res s.[i] in
      loop (i + 1) elt
    else res
  in loop 0 ini

module CString = struct
  let fold_right f str ini =
    let len = String.length str in
    let rec loop i =
      if i < len then f str.[i] (loop (i + 1))
      else ini
    in loop 0
end

module Matrix = struct
  type 'a matrix = 'a array array
  let init nr nc f = Array.(init nr (fun r -> Array.init nc (f r)))
  let map f = Array.(map (map f))
  let mapi f = Array.(mapi (fun r -> mapi (f r)))
  let iter f = Array.(iter (iter f))
  let iteri f = Array.(iteri (fun r -> iteri (f r)))
end

let split_lines = String.split_on_char '\n'

let split_tabs = String.split_on_char '\t'

let tagger_time f x =
  let t_1 = Unix.gettimeofday () in
  let res = f x in
  let t_2 = Unix.gettimeofday () in
  CLog.info "elapsed time: %.1f s" (t_2 -. t_1);
  res

let tagger_html_to_int s =
  sscanf s "#%02x%02x%02x" (fun r g b -> r, g, b)

let tagger_html_to_int16 s = 
  let r, g, b = tagger_html_to_int s in 
  r lsl 8, g lsl 8, b lsl 8

let tagger_html_to_float =
  let f x = float x /. 255.0 in
  fun s -> let r, g, b = tagger_html_to_int s in f r, f g, f b

let tagger_float_to_int =
  let f x = truncate (x *. 255.0) in
  fun r g b -> (f r, f g, f b)

let tagger_float_to_html r g b =
  let r, g, b = tagger_float_to_int r g b in
  sprintf "#%02x%02x%02x" r g b

let memoize f =
  let mem = ref (`F f) in
  (fun () -> match !mem with
    | `F f -> let x = f () in mem := `R x; x
    | `R x -> x)
