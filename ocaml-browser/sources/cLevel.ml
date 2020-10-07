(* CastANet - cLevel.ml *)

open Printf
open Morelib



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
    | unknown_string -> CLog.error ~code:17 "(CLevel.of_string) Wrong annotation level %S" unknown_string



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
    | `COLONIZATION -> ["#80b3ff99"; "#bec8b799"; "#ffaaaa99"]
    | `ARB_VESICLES -> ["#80b3ff99"; "#afe9c699"; "#bec8b7"; "#ffaaaa99"]
    | `ALL_FEATURES -> ["#80b3ff99"; "#afe9c699"; "#ffeeaa99"; "#eeaaff99";
                        "#ffb38099"; "#bec8b799"; "#ffaaaa99" ]


(* let strings = ["Colonization"; "Arbuscules/Vesicles"; "All features"] *)


