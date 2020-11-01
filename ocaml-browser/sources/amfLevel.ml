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
    | unknown_string -> AmfLog.error ~code:17 "(AmfLevel.of_string) Wrong annotation level %S" unknown_string



let to_header = function
    | `COLONIZATION -> ['Y'; 'N'; 'X']
    | `ARB_VESICLES -> ['A'; 'V'; 'N'; 'X']
    | `ALL_FEATURES -> ['A'; 'V'; 'E'; 'I'; 'H'; 'R'; 'X']

let chars lvl = CSet.of_list (to_header lvl)

let char_index lvl chr = to_header lvl
    |> List.to_seq
    |> String.of_seq
    |> (fun str -> String.index str chr)

let all_chars_list =
    chars `COLONIZATION
    |> CSet.union (chars `ARB_VESICLES)
    |> CSet.union (chars `ALL_FEATURES)
    |> CSet.elements


let of_header t =
    match List.map Char.uppercase_ascii t with
    | ['Y'; 'N'; 'X'] -> `COLONIZATION
    | ['A'; 'V'; 'N'; 'X'] -> `ARB_VESICLES
    | ['A'; 'V'; 'E'; 'I'; 'H'; 'R'; 'X'] -> `ALL_FEATURES
    | _ -> invalid_arg "(AmfLevel.of_header) Malformed table header"



let all_flags = [`COLONIZATION; `ARB_VESICLES; `ALL_FEATURES]
let lowest = `COLONIZATION
let highest = `ALL_FEATURES



let others = function
    | `COLONIZATION -> [`ARB_VESICLES; `ALL_FEATURES]
    | `ARB_VESICLES -> [`COLONIZATION; `ALL_FEATURES]
    | `ALL_FEATURES -> [`COLONIZATION; `ARB_VESICLES]


let symbols = function
    | `COLONIZATION -> ["M+"; "M−"; "Bkg"]
    | `ARB_VESICLES -> ["Arb"; "Ves"; "M−"; "Bkg"]
    | `ALL_FEATURES -> ["Arb"; "Ves"; "IRH"; "ERH"; "Hyp"; "Root"; "Bkg"]


let colors = function
    | `COLONIZATION -> ["#173ec2"; "#c217ba"; "#51c217"]
    | `ARB_VESICLES -> ["#80b3ff99"; "#afe9c699"; "#bec8b7"; "#ffaaaa99"]
    | `ALL_FEATURES -> ["#80b3ff99"; "#afe9c699"; "#ffeeaa99"; "#eeaaff99";
                        "#ffb38099"; "#bec8b799"; "#ffaaaa99" ]

(* Old color set:
    ["#80b3ff99"; "#bec8b799"; "#ffaaaa99"] 
*)

(* let strings = ["Colonization"; "Arbuscules/Vesicles"; "All features"] *)



module type ANNOTATION_RULES = sig
    val add_add : char -> Morelib.CSet.t
    val add_rem : char -> Morelib.CSet.t
    val rem_add : char -> Morelib.CSet.t
    val rem_rem : char -> Morelib.CSet.t
end

let cset_of_string str = CSet.of_seq (String.to_seq str)

module Colonization = struct
    let add_add _ = Morelib.CSet.empty
    let add_rem = function
        | 'Y' -> cset_of_string "NX"
        | 'N' -> cset_of_string "YX"
        | 'X' -> cset_of_string "YN"
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.Colonization.add_rem: Invalid argument %C" chr
    let rem_add _ = Morelib.CSet.empty
    let rem_rem _ = Morelib.CSet.empty
end

module Arb_vesicles = struct
    let add_add _ = Morelib.CSet.empty
    let add_rem = function
        | 'A' | 'V' -> cset_of_string "NX"
        | 'N' -> cset_of_string "AVX"
        | 'X' -> cset_of_string "AVN"
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.Arb_vesicles.add_rem: Invalid argument %C" chr
    let rem_add _ = Morelib.CSet.empty
    let rem_rem _ = Morelib.CSet.empty
end

module All_features = struct
    let add_add = function
        | 'A' | 'V' | 'I' | 'H' -> Morelib.CSet.singleton 'R'
        | 'E' | 'R' | 'X' -> Morelib.CSet.empty
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.All_features.add_add: Invalid argument %C" chr
    let add_rem = function
        | 'A' | 'V' | 'I' | 'H' | 'E' | 'R' -> Morelib.CSet.singleton 'X'
        | 'X' -> cset_of_string "AVEIHR"
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.Arb_vesicles.add_rem: Invalid argument %C" chr
    let rem_add _ = Morelib.CSet.empty
    let rem_rem = function
        | 'R' -> cset_of_string "AVIH"
        | 'A' | 'V' | 'I' | 'H' | 'E' | 'X' -> Morelib.CSet.empty
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.Arb_vesicles.add_rem: Invalid argument %C" chr
end


let rules = function
    | `COLONIZATION -> (module Colonization : ANNOTATION_RULES)
    | `ARB_VESICLES -> (module Arb_vesicles : ANNOTATION_RULES)
    | `ALL_FEATURES -> (module All_features : ANNOTATION_RULES)
