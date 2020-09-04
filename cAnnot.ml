(* CastANet - cAnnot.ml *)

open CExt

type lock = string
type hold = string

module type S = sig
  val diff : string -> string
  val get : CLevel.t -> string -> hold * lock
end

let generator str col arb all =
  let module M = struct
    let diff s = if s = "" then str else EStringSet.diff str s
    let get = function
      | `COLONIZATION -> col
      | `ARB_VESICLES -> arb
      | `ALL_FEATURES -> all
  end in (module M : S)

let m_colonization = 
  let col = function
    | "Y" -> "", "NX"
    | "N" -> "", "YX"
    |  _  -> "", "YN"
  and arb = function
    | "Y" -> "", "NX"
    | "N" -> "N", "AVX"
    |  _  -> "X", "AVN"
  and all = function
    | "Y" -> "", "X"
    | "N" -> "R", "AVIEHX"
    |  _  -> "X", "AVIEHR"
  in generator "YNX" ~col ~arb ~all

let m_arb_vesicles =
  let col = function
    | "A" | "V" -> "Y", "NX"
    | "N" -> "N", "YX"
    |  _  -> "X", "YN"
  and arb = function
    | "A" | "V" -> "", "NX"
    | "N" -> "", "AVX"
    |  _  -> "", "AVN"
  and all = function
    | "A" -> "AR", "X"
    | "V" -> "VR", "X"
    | "N" -> "R", "AVIEHX"
    |  _  -> "X", "AVIEHR"
  in generator "AVNX" ~col ~arb ~all

let m_all_features =
  let col = function
    | "A" | "V" | "I" | "E" | "H" -> "Y", "NX"
    | "R" -> "", "X"
    |  _  -> "X", "YN"
  and arb = function
    | "A" -> "A", "NX"
    | "V" -> "V", "NX"
    | "I" | "E" | "H" -> "", "NX"
    | "R" -> "", "X"
    |  _  -> "X", "AVN"
  and all = function
    | "A" | "V" | "I" | "H" -> "R", "X"
    | "E" -> "", "X"
    | "R" -> "", "X"
    |  _  -> "", "AVIEHR"
  in generator "AVIEHRX" ~col ~arb ~all

let get = function
  | `COLONIZATION -> m_colonization
  | `ARB_VESICLES -> m_arb_vesicles
  | `ALL_FEATURES -> m_all_features

let chars lvl = let open (val (get lvl) : S) in diff ""

let char_list lvl = List.init (String.get) (chars lvl)

(* Not hardcoded, should the list change in the future. *)
let all_chars =
  let col = chars `COLONIZATION
  and arb = chars `ARB_VESICLES
  and all = chars `ALL_FEATURES in
  EStringSet.(union (union col arb) all)

let all_chars_list = List.init (String.get) all_chars

let rule lvl = let open (val (get lvl) : S) in get

let others elt lvl =
  let str = String.uppercase_ascii (
    match elt with
    | `CHR chr -> String.make 1 chr
    | `STR str -> str
  ) in 
  let open (val (get lvl) : S) in other str

let rec mem elt lvl = 
  match elt with
  | `CHR chr -> String.contains (chars lvl) (Char.uppercase_ascii chr)
  | `STR str -> List.for_all (fun c -> mem (`CHR c) lvl) (EText.explode str)

