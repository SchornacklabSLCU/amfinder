(* CastANet - cExt.ml *)

(* Operations on string sets. *)
module Ext_StringSet = struct
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

module Ext_File = struct
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



module Ext_Matrix = struct

    open Array

    type 'a t = 'a array array

    let dim t =
        let r = length t in
        if r = 0 then (0, 0) else r, length t.(0)

    let get t r c = t.(r).(c)
    let get_opt t r c = try Some t.(r).(c) with _ -> None

    let set t r c x = t.(r).(c) <- x

    let make nrows ncols x = init nrows (fun _ -> make ncols x)
    let init nrows ncols f = init nrows (fun r -> init ncols (f r))

    let map f = map (map f)
    let mapi f = mapi (fun r -> mapi (f r))

    let iter f = iter (iter f)
    let iteri f = iteri (fun r -> iteri (fun c -> f ~r ~c))

    let fold f ini t = 
        let res = ref ini in
        iteri (fun r -> iteri (fun c x -> res := f ~r ~c !res x)) t;
        !res

    let copy ?(dat = id) mat = Array.(map (map dat)) mat

    let to_string ~cast t =
        map (map cast) t
        |> map to_list
        |> map (String.concat "\t")
        |> to_list
        |> String.concat "\n"

    let to_string_rc ~cast t =
        mapi (fun r -> (mapi (fun c -> cast ~r ~c))) t
        |> map to_list
        |> map (String.concat "\t")
        |> to_list
        |> String.concat "\n"

    let of_string ~cast s =
        String.split_on_char '\n' s
        |> of_list
        |> map (String.split_on_char '\t')
        |> map of_list
        |> map (map cast)

    let of_string_rc ~cast s =
        String.split_on_char '\n' s
        |> of_list
        |> map (String.split_on_char '\t')
        |> map of_list
        |> mapi (fun r -> (mapi (fun c -> cast ~r ~c)))

end



module Ext_Text = struct

    open String
    
    let explode s = List.init (length s) (get s)
    let implode t = concat "" (List.map (String.make 1) t)
end



let time f x =
  let t_1 = Unix.gettimeofday () in
  let res = f x in
  let t_2 = Unix.gettimeofday () in
  CLog.info "Elapsed time: %.1f s" (t_2 -. t_1);
  res



(* Memoized values with possible reinitialization. *)
module Ext_Memoize = struct
  let flag = ref 0 (* Main flag. *)

  type 'a t = {
    mutable flag : int; (* Local flag. *)
    mutable data : [`F of (unit -> 'a) | `R of 'a]; (* Memoized data. *)
  }

  let exec f mem = let x = f () in mem.data <- `R x; x

  let create ?label ?(one = false) f =
    let mem = { flag = if one then -1 else 0; data = `F f } in
    (fun () -> match mem.data with
      | `F f -> exec f mem (* Runs the function, store and return result. *)
      | `R x -> 
        if mem.flag >= 0 && !flag > mem.flag then (
          (* The main flag has changed: recompute, store and return result. *)
          Gaux.may (CLog.info "Recomputing data for '%s'") label;
          let x = exec f mem in 
          mem.flag <- mem.flag + 1;
          x
        ) else x (* Return the previously computed result. *)
    )

  let forget () = incr flag
end
