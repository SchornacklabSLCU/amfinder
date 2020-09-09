(* CastANet - cLevel.ml *)

open CExt

type t = [
  | `COLONIZATION (* colonized vs non-colonized vs background                 *)
  | `ARB_VESICLES (* [arbuscules, vesicles] vs non-colonized vs background    *)
  | `ALL_FEATURES (* [ERH, [root, [arb, ves, IRH, hyphopodia]]] vs background *)
]

let flags = [`COLONIZATION; `ARB_VESICLES; `ALL_FEATURES]
let strings = ["Colonization"; "Arbuscules/Vesicles"; "All features"]

let lowest = `COLONIZATION
let highest = `ALL_FEATURES

let others = function
  | `COLONIZATION -> [`ARB_VESICLES; `ALL_FEATURES]
  | `ARB_VESICLES -> [`COLONIZATION; `ALL_FEATURES]
  | `ALL_FEATURES -> [`COLONIZATION; `ARB_VESICLES]

module Colors = struct
  let colonization = ["#80b3ff"; "#bec8b7"; "#ffaaaa"]
  let arb_vesicles = ["#80b3ff"; "#afe9c6"; "#bec8b7"; "#ffaaaa"]
  let all_features = ["#80b3ff"; "#afe9c6"; "#ffeeaa"; "#eeaaff";
                      "#ffb380"; "#bec8b7"; "#ffaaaa" ]
end

let colors = function
  | `COLONIZATION -> Colors.colonization
  | `ARB_VESICLES -> Colors.arb_vesicles
  | `ALL_FEATURES -> Colors.all_features  

let to_string = function
  | `COLONIZATION -> "`COLONIZATION"
  | `ARB_VESICLES -> "`ARB_VESICLES"
  | `ALL_FEATURES -> "`ALL_FEATURES"

let of_string = function
  | "`COLONIZATION" -> `COLONIZATION
  | "`ARB_VESICLES" -> `ARB_VESICLES
  | "`ALL_FEATURES" -> `ALL_FEATURES
  | _               -> invalid_arg "CLevel.of_string" 
