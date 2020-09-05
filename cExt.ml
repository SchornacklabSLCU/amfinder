(* CastANet - cExt.ml *)

(* Operations on string sets. *)
module EStringSet = struct
  open Printf
  let sort s = String.to_seq s
    |> List.of_seq
    |> List.sort Char.compare
    |> List.to_seq
    |> String.of_seq
  let union s1 s2 =
    let res = ref s2 in
    String.iter (fun chr -> 
      if not (String.contains s2 chr) then
        res := sprintf "%s%c" !res chr
    ) s1;
    sort !res
  let inter s1 s2 =
    let res = ref "" in
    String.iter (fun chr ->
      if String.contains s2 chr then 
        res := sprintf "%s%c" !res chr
    ) s1;
    sort !res
  let diff s1 s2 =
    let res = ref "" in 
    String.iter (fun chr ->
      if not (String.contains s2 chr) then
        res := sprintf "%s%c" !res chr
    ) s1;
    sort !res
end

module EFile = struct
  let read ?(binary = false) ?(trim = true) str = 
    let ich = (if binary then open_in_bin else open_in) str in
    let len = in_channel_length ich in
    let buf = Buffer.create len in
    Buffer.add_channel buf ich len;
    close_in ich;
    let str = Buffer.contents buf in
    if trim then String.trim str else str
end

external id : 'a -> 'a = "%identity"

module EMatrix = struct
  type 'a t = 'a array array
  let get t r c = t.(r).(c)
  let get_opt t r c = try Some t.(r).(c) with _ -> None
  let init nr nc f = Array.(init nr (fun r -> init nc (f r)))
  let map f = Array.(map (map f))
  let mapi f = Array.(mapi (fun r -> mapi (f r)))
  let iter f = Array.(iter (iter f))
  let iteri f = Array.(iteri (fun r -> iteri (fun c -> f ~r ~c)))
  let fold f ini t = 
    let res = ref ini in
    Array.(iteri (fun r -> iteri (fun c x -> res := f ~r ~c !res x))) t;
    !res
  let copy ?(dat = id) mat = Array.(map (map dat)) mat
  let to_string ~cast t =
    Array.map (Array.map cast) t
    |> Array.map Array.to_list
    |> Array.map (String.concat "\t")
    |> Array.to_list
    |> String.concat "\n"
  let of_string ~cast s =
    String.split_on_char '\n' s
    |> Array.of_list
    |> Array.map (String.split_on_char '\t')
    |> Array.map Array.of_list
    |> Array.map (Array.map cast)
end


module EText = struct
  let explode s = String.(List.init (length s) (get s))
  let implode t = String.concat "" (List.map (String.make 1) t)
end

module ESplit = struct
  let lines = String.split_on_char '\n'
  let tabs = String.split_on_char '\t'
  let colons = String.split_on_char ':'
  let semicolons = String.split_on_char ';'
  let commas = String.split_on_char ','
  let spaces = String.split_on_char ' '
end


module EMaybe = struct
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


module EColor = struct
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


module EDraw = struct
  let square ?(clr = "#cc0000") ?(a = 1.0) edge =
    let open Cairo in
    let edge = if edge <= 2 then 2 else edge
    and a = if a >= 0.0 && a <= 1.0 then a else 1.0 in
    let surface = Image.(create ARGB32 ~w:edge ~h:edge) in
    let t = create surface in
    set_antialias t ANTIALIAS_SUBPIXEL;
    let r, g, b = EColor.html_to_float clr in
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
  CLog.info "Elapsed time: %.1f s" (t_2 -. t_1);
  res


(* Memoized values with possible reinitialization. *)
module EMemoize = struct
  let flag = ref 0 (* Main flag. *)

  type 'a t = {
    mutable flag : int; (* Local flag. *)
    mutable data : [`F of (unit -> 'a) | `R of 'a]; (* Memoized data. *)
  }

  let exec f mem = let x = f () in mem.data <- `R x; x

  let create ?lbl ?(one = false) f =
    let mem = { flag = if one then -1 else 0; data = `F f } in
    (fun () -> match mem.data with
      | `F f -> exec f mem (* Runs the function, store and return result. *)
      | `R x -> 
        if mem.flag >= 0 && !flag > mem.flag then (
          (* The main flag has changed: recompute, store and return result. *)
          Gaux.may (CLog.info "Recomputing data for '%s'") lbl;
          let x = exec f mem in 
          mem.flag <- mem.flag + 1;
          x
        ) else x (* Return the previously computed result. *)
    )

  let forget () = incr flag
end
