(* CastANet - cTile.ml *)

open CExt
open Scanf
open Printf

type t = {
  mutable user : string;
  mutable lock : string;
  mutable hold : string;
}

let as_string = function
  | `CHR chr -> String.make 1 (Char.uppercase_ascii chr)
  | `STR str -> String.uppercase_ascii str

type layer = [ `USER | `HOLD | `LOCK ]

let create () = { user = ""; lock = ""; hold = "" }

let make ?(user = `STR "") ?(lock = `STR "") ?(hold = `STR "") () = 
  let user = as_string user
  and lock = as_string lock
  and hold = as_string hold in {user; lock; hold}

let to_string t = sprintf "[%S %S %S]" t.user t.lock t.hold

let of_string s = 
  let import s = sscanf s "[%S %S %S]"
    (fun x y z -> {user = x; lock = y; hold = z})
  in try import s with _ -> invalid_arg s

let get t = function
  | `USER -> t.user
  | `LOCK -> t.lock
  | `HOLD -> t.hold

let apply f t = function
  | `USER -> (fun x -> t.user <- f t.user x)
  | `LOCK -> (fun x -> t.lock <- f t.lock x)
  | `HOLD -> (fun x -> t.hold <- f t.hold x)



let set = apply (fun _ -> as_string)
let add = apply (fun x y -> EStringSet.union x (as_string y))
let remove = apply (fun x y -> EStringSet.diff x (as_string y))

let exists src = function
  | `CHR chr -> String.contains src chr
  | `STR str -> List.for_all (String.contains src) (Ext_Text.explode str)

let is_empty t = function
  | `USER -> t.user = ""
  | `LOCK -> t.lock = ""
  | `HOLD -> t.hold = ""

let mem t = function
  | `USER -> exists t.user
  | `LOCK -> exists t.lock
  | `HOLD -> exists t.hold
