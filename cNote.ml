(* CastANet - cNote.ml *)

type t = {
  mutable user : string;
  mutable lock : string;
  mutable hold : string;
(*mutable pred : string; Annotations given by the prediction. *)
}

type layer = [ `USER | `HOLD | `LOCK ]

let create () = {user = ""; lock = ""; hold = ""}

let to_string {user; lock; hold} = sprintf "%s %s %s" user lock hold

let of_string s = 
  try
    sscanf s "%[A-Z] %[A-Z] %[A-Z]"
      (fun x y z -> Some {user = x; lock = y; hold = z})
  with _ -> invalid_arg s

let get t = function
  | `USER -> t.user
  | `LOCK -> t.lock
  | `HOLD -> t.hold
