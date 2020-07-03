(* CastANet - cSettings.ml *)

module Ref = struct
  let image = ref None
  let palette = ref `CIVIDIS
end

module Set = struct
  let image x = 
    if Sys.file_exists x then Ref.image := Some x
    else CLog.warning "File '%s' not found" x
  let palette x =
    match String.uppercase_ascii x with
    | "CIVIDIS" -> Ref.palette := `CIVIDIS
    | "PLASMA"  -> Ref.palette := `PLASMA
    | "VIRIDIS" -> Ref.palette := `VIRIDIS
    | other -> CLog.warning "Unknown palette '%s'" other
end

let usage = "castanet-editor [OPTIONS] <IMAGE>"

let specs = Arg.align [
  "--palette", Arg.String Set.palette,
    " Color palette for annotation confidence (default: CIVIDIS).";
]

let initialize () =
  Arg.parse specs Set.image usage;
  if !Ref.image = None then CLog.error "%s" usage

let image () = match !Ref.image with Some x -> x | _ -> assert false
let palette () = !Ref.palette
