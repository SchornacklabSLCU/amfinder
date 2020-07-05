(* CastANet - cLog.ml *)

let message f cha typ fmt =
  Printf.kfprintf f cha ("(CastANet) %s: " ^^ fmt ^^ ".\n%!") typ

let info fmt = message ignore stdout "Info" fmt 
let warning fmt = message ignore stderr "Warning" fmt 
let error ?(code = 2) fmt = message (fun _ -> exit code) stderr "Error" fmt
let usage () = error "%s" "castanet-editor [OPTIONS] <IMAGE>"
