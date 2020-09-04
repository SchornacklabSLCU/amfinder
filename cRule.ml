(* CastANet - cRule.ml *)

open CExt

type lock = string
type hold = string

module Colonization = struct

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
end


module Arb_vesicles = struct

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
end


module All_features = struct

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
end

let get = function
  | `COLONIZATION -> Rule.Colonization.get
  | `ARB_VESICLES -> Rule.Arb_vesicles.get
  | `ALL_FEATURES -> Rule.All_features.get
