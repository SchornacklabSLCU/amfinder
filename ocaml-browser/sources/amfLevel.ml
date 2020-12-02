(* CastANet - amfLevel.ml *)

open Printf
open Morelib

type level = COLONIZATION | MYC_STRUCTURES

let to_string = function
    | COLONIZATION -> "colonization"
    | MYC_STRUCTURES -> "myc_structures"

let of_string str =
    match String.lowercase_ascii str with
    | "colonization" -> COLONIZATION
    | "myc_structures" -> MYC_STRUCTURES
    | unknown -> AmfLog.error ~code:17 "(AmfLevel.of_string) Wrong annotation level %S" unknown

let to_header = function
    | COLONIZATION -> ['Y'; 'N'; 'X']
    | MYC_STRUCTURES -> ['A'; 'V'; 'E'; 'I'; 'H'; 'R'; 'X']

let chars lvl = CSet.of_list (to_header lvl)

let char_index lvl chr = to_header lvl
    |> List.to_seq
    |> String.of_seq
    |> (fun str -> String.index str chr)

let all_chars_list =
    chars COLONIZATION
    |> CSet.union (chars MYC_STRUCTURES)
    |> CSet.elements

let of_header t =
    match List.map Char.uppercase_ascii t with
    | ['Y'; 'N'; 'X'] -> COLONIZATION
    | ['A'; 'V'; 'E'; 'I'; 'H'; 'R'; 'X'] -> MYC_STRUCTURES
    | _ -> invalid_arg "(AmfLevel.of_header) Malformed table header"

let all_flags = [COLONIZATION; MYC_STRUCTURES]
let lowest = COLONIZATION
let highest = MYC_STRUCTURES

let others = function
    | COLONIZATION -> [MYC_STRUCTURES]
    | MYC_STRUCTURES -> [COLONIZATION]

let symbols = function
    | COLONIZATION -> ["M+"; "M−"; "Bkg"]
    | MYC_STRUCTURES -> ["Arb"; "Ves"; "IRH"; "ERH"; "Hyp"; "Root"; "Bkg"]

let colors = function
    | COLONIZATION -> ["#173ec299"; "#c217ba99"; "#51c21799"]
    | MYC_STRUCTURES -> ["#80b3ff99"; "#afe9c699"; "#ffeeaa99"; "#eeaaff99";
                        "#ffb38099"; "#bec8b799"; "#ffaaaa99" ]

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

module Myc_structures = struct
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
    | COLONIZATION -> (module Colonization : ANNOTATION_RULES)
    | MYC_STRUCTURES -> (module Myc_structures : ANNOTATION_RULES)
