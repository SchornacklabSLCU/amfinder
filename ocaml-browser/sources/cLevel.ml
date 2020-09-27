(* CastANet - cLevel.ml *)

open CExt



type t = [
    | `COLONIZATION
    | `ARB_VESICLES
    | `ALL_FEATURES
]



let to_string = function
    | `COLONIZATION -> "colonization"
    | `ARB_VESICLES -> "arb_vesicles"
    | `ALL_FEATURES -> "all_features"



let of_string str =
    match String.lowercase_ascii str with
    | "colonization" -> `COLONIZATION
    | "arb_vesicles" -> `ARB_VESICLES
    | "all_features" -> `ALL_FEATURES
    | _               -> invalid_arg "(CLevel.of_string) Wrong annotation level" 



let to_header = function
    | `COLONIZATION -> ['Y'; 'N'; 'X']
    | `ARB_VESICLES -> ['A'; 'V'; 'N'; 'X']
    | `ALL_FEATURES -> ['A'; 'V'; 'E'; 'I'; 'H'; 'R'; 'X']



let of_header t =
    match List.map Char.uppercase_ascii t with
    | ['Y'; 'N'; 'X'] -> `COLONIZATION
    | ['A'; 'V'; 'N'; 'X'] -> `ARB_VESICLES
    | ['A'; 'V'; 'E'; 'I'; 'H'; 'R'; 'X'] -> `ALL_FEATURES
    | _ -> invalid_arg "(CLevel.of_header) Malformed table header"



let all_flags = [`COLONIZATION; `ARB_VESICLES; `ALL_FEATURES]
let lowest = `COLONIZATION
let highest = `ALL_FEATURES



let others = function
    | `COLONIZATION -> [`ARB_VESICLES; `ALL_FEATURES]
    | `ARB_VESICLES -> [`COLONIZATION; `ALL_FEATURES]
    | `ALL_FEATURES -> [`COLONIZATION; `ARB_VESICLES]



let colors = function
    | `COLONIZATION -> ["#80b3ff"; "#bec8b7"; "#ffaaaa"]
    | `ARB_VESICLES -> ["#80b3ff"; "#afe9c6"; "#bec8b7"; "#ffaaaa"]
    | `ALL_FEATURES -> ["#80b3ff"; "#afe9c6"; "#ffeeaa"; "#eeaaff";
                        "#ffb380"; "#bec8b7"; "#ffaaaa" ]


(* let strings = ["Colonization"; "Arbuscules/Vesicles"; "All features"] *)


