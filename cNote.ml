(* CastANet - cNote.ml *)

open Scanf
open Printf

type t = {
  mutable user : string;
  mutable lock : string;
  mutable hold : string;
}

type layer = [ `USER | `HOLD | `LOCK ]

let create () = { user = ""; lock = ""; hold = "" }

let to_string t = sprintf "%s %s %s" t.user t.lock t.hold

let of_string s = 
  let import s = sscanf s "%[A-Z] %[A-Z] %[A-Z]"
    (fun x y z -> {user = x; lock = y; hold = z})
  in try import s with _ -> invalid_arg s

let get t = function
  | `USER -> t.user
  | `LOCK -> t.lock
  | `HOLD -> t.hold

let set t x = function
  | `USER -> t.user <- x
  | `LOCK -> t.lock <- x
  | `HOLD -> t.hold <- x
