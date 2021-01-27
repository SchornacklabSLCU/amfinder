(* AMFinder - morelib.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)


module List = struct
    include List

    let iteri2 f =
        let rec loop i x y =
            match x, y with
            | [], [] -> ()
            | a :: x, b :: y -> let () = f i a b in
                loop (i + 1) x y
            | _ -> invalid_arg "List.iteri2"
        in loop 0
end



module CSet = Set.Make(Char)

module StringSet = struct

    open Printf

    let sort str =
        String.to_seq str
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



module File = struct
    let read ?(binary = false) ?(trim = true) str = 
        let ich =
            match binary with
            | true -> open_in_bin str
            | false -> open_in str in
        let len = in_channel_length ich in
        let buf = Buffer.create len in
        Buffer.add_channel buf ich len;
        close_in ich;
        let str = Buffer.contents buf in
        if trim then String.trim str else str
end



external id : 'a -> 'a = "%identity"



module Matrix = struct

    type 'a t = 'a Array.t Array.t

    let dim t =
        let r = Array.length t in
        if r = 0 then (0, 0) else r, Array.length t.(0)

    let get_opt t ~r ~c = try Some t.(r).(c) with _ -> None

    let get t ~r ~c =
        match get_opt t ~r ~c with
        | None -> AmfLog.error ~code:Err.out_of_bounds 
            "Morelib.Matrix.get: Out of range (r=%d c=%d)" r c
        | Some x -> x

    let set t ~r ~c x = t.(r).(c) <- x

    let make ~r ~c x = Array.init r (fun _ -> Array.make c x)
    let init ~r ~c f = Array.init r (fun r -> Array.init c (fun c -> f ~r ~c))

    let map f = Array.(map (map f))
    let mapi f = Array.(mapi (fun r -> mapi (fun c -> f ~r ~c)))
    let map2 f = Array.(map2 (map2 f))

    let iter f = Array.(iter (iter f))
    let iteri f = Array.(iteri (fun r -> iteri (fun c -> f ~r ~c)))
    let iter2 f = Array.(iter2 (iter2 f))

    let fold f ini t = 
        let res = ref ini in
        Array.iteri (fun r -> Array.iteri (fun c x -> res := f ~r ~c !res x)) t;
        !res

    let copy ?(dat = id) mat = Array.map (Array.map dat) mat

    let to_string ~cast t =
        Array.map (Array.map cast) t
        |> Array.map Array.to_list
        |> Array.map (String.concat "\t")
        |> Array.to_list
        |> String.concat "\n"

    let to_string_rc ~cast t =
        Array.mapi (fun r -> (Array.mapi (fun c -> cast ~r ~c))) t
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

    let of_string_rc ~cast s =
        String.split_on_char '\n' s
        |> Array.of_list
        |> Array.map (String.split_on_char '\t')
        |> Array.map Array.of_list
        |> Array.mapi (fun r -> (Array.mapi (fun c -> cast ~r ~c)))

end



module Text = struct

    open String
    
    let explode s = List.init (length s) (get s)
    let implode t = concat "" (List.map (String.make 1) t)
end



(* Memoized values with possible reinitialization. *)
module Memoize = struct
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
          Gaux.may (AmfLog.info "Recomputing data for '%s'") label;
          let x = exec f mem in 
          mem.flag <- mem.flag + 1;
          x
        ) else x (* Return the previously computed result. *)
    )

  let forget () = incr flag
end
