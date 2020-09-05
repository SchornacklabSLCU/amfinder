(* CastANet - cChangeLog.ml *)

open CExt

type t = {
  user : (CLevel.t * string) list;
  lock : (CLevel.t * string) list;
  hold : (CLevel.t * string) list;
}

let create () = {user = []; lock = []; hold = []}

let get chg = function
  | `USER -> chg.user
  | `LOCK -> chg.lock
  | `HOLD -> chg.hold

let set chg = function
  | `USER -> (fun x -> {chg with chg.user <- x})
  | `LOCK -> (fun x -> {chg with chg.lock <- x})
  | `HOLD -> (fun x -> {chg with chg.hold <- x})

let add chg lay ((lvl, str) as dat) =
  let elt = get chg lay in
  match List.assoc_opt lvl elt with
  | None -> set chg lay (dat :: elt)
  | Some log -> let uni = EStringSet.union log str in
    if uni = log (* nothing has changed *) then chg 
    else set chg lay ((lvl, uni) :: List.remove_assoc lvl elt)

let remove chg lay ((lvl, str) as dat) =
  let elt = get chg lay in
  match List.assoc_opt lvl elt with
  | None -> (* already not there. *) chg
  | Some log -> let rem = List.remove_assoc lvl elt
    and dif = EStringSet.dif log str in
    set chg lay (if str = "*" || dif = "" then rem else (lvl, dif) :: rem)
