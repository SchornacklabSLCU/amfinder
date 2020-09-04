(* CastANet - cAnnot.ml *)

open CExt

type lock = string
type hold = string

module type S = sig
  val other : string -> string
  val colonization : string -> string * string
  val arb_vesicles : string -> string * string
  val all_features : string -> string * string
  val get : CLevel.t -> string -> string * string
end

let m_colonization =
  let module M = struct
    let other = EStringSet.diff "YNX"
    let arb_vesicles = function
      | "Y" -> "", "NX"
      | "N" -> "N", "AVX"
      |  _  -> "X", "AVN"
    let all_features = function
      | "Y" -> "", "X"
      | "N" -> "R", "AVIEHX"
      |  _  -> "X", "AVIEHR"
    let colonization = function
      | "Y" -> "", "NX"
      | "N" -> "", "YX"
      |  _  -> "", "YN"
    let get = function
      | `COLONIZATION -> colonization
      | `ARB_VESICLES -> arb_vesicles
      | `ALL_FEATURES -> all_features
  end in (module M : S)

let m_arb_vesicles =
  let module M = struct
    let other = EStringSet.diff "AVNX"
    let colonization = function
      | "A" | "V" -> "Y", "NX"
      | "N" -> "N", "YX"
      |  _  -> "X", "YN"
    let all_features = function
      | "A" -> "AR", "X"
      | "V" -> "VR", "X"
      | "N" -> "R", "AVIEHX"
      |  _  -> "X", "AVIEHR"
    let arb_vesicles = function
      | "A" | "V" -> "", "NX"
      | "N" -> "", "AVX"
      |  _  -> "", "AVN"
    let get = function
      | `COLONIZATION -> colonization
      | `ARB_VESICLES -> arb_vesicles
      | `ALL_FEATURES -> all_features
  end in (module M : S)

let m_all_features =
  let module M = struct
    let other = EStringSet.diff "AVIEHRX"
    let colonization = function
      | "A" | "V" | "I" | "E" | "H" -> "Y", "NX"
      | "R" -> "", "X"
      |  _  -> "X", "YN"
    let arb_vesicles = function
      | "A" -> "A", "NX"
      | "V" -> "V", "NX"
      | "I" | "E" | "H" -> "", "NX"
      | "R" -> "", "X"
      |  _  -> "X", "AVN"
    let all_features = function
      | "A" | "V" | "I" | "H" -> "R", "X"
      | "E" -> "", "X"
      | "R" -> "", "X"
      |  _  -> "", "AVIEHR"
    let get = function
      | `COLONIZATION -> colonization
      | `ARB_VESICLES -> arb_vesicles
      | `ALL_FEATURES -> all_features
  end in (module M : S)

let get = function
  | `COLONIZATION -> m_colonization
  | `ARB_VESICLES -> m_arb_vesicles
  | `ALL_FEATURES -> m_all_features

let get_rule lvl = let open (val (get lvl) : S) in get

let others elt lvl =
  let str = String.uppercase_ascii (
    match elt with
    | `CHR chr -> String.make 1 chr
    | `STR str -> str
  ) in 
  let open (val (get lvl) : S) in other str
