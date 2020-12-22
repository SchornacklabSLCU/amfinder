(* AMFinder - amfLevel.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

open Printf
open Morelib

type level = RootSegm | IRStruct

let root_segmentation = RootSegm
let intraradical_structures = IRStruct

let is_root_segm x = x = RootSegm 
let is_ir_struct x = x = IRStruct

let to_header = function
    | RootSegm -> ['Y'; 'N'; 'X']
    | IRStruct -> ['A'; 'V'; 'H']

let to_charset lvl = CSet.of_list (to_header lvl) 

let to_string = function
    | RootSegm -> "RootSegm"
    | IRStruct -> "IRStruct"

let of_string str =
    match String.uppercase_ascii str with (* case-insensitive. *)
    | "ROOTSEGM" | "COLONIZATION" -> RootSegm
    | "IRSTRUCT" -> IRStruct
    | unknown -> AmfLog.error ~code:Err.Level.unknown_level
        "(AmfLevel.of_string) Wrong annotation level %S" unknown

let of_header t =
    match List.map Char.uppercase_ascii t with (* case-insensitive. *)
    | ['Y'; 'N'; 'X'] -> RootSegm
    | ['A'; 'V'; 'H'] -> IRStruct
    | _ -> AmfLog.error ~code:Err.Level.invalid_level_header
        "(AmfLevel.of_header) Malformed table header"

let chars lvl = CSet.of_list (to_header lvl)

let char_index lvl chr = to_header lvl
    |> List.to_seq
    |> String.of_seq
    |> (fun str -> String.index str chr)

let all_chars_list =
    chars RootSegm
    |> CSet.union (chars IRStruct)
    |> CSet.elements

let all_flags = [RootSegm; IRStruct]
let lowest = RootSegm
let highest = IRStruct

let others = function
    | RootSegm -> [IRStruct]
    | IRStruct -> [RootSegm]

let symbols = function
    | RootSegm -> ["AM fungi (M+)"; "Plant root (M−)"; "Background (×)"]
    | IRStruct -> ["Arbuscule (A)";  "Vesicle (V)";        "Hypha (H)"]

let icon_text = function
    | RootSegm -> [('Y', "M+"); ('N', "M−"); ('X', "×")]
    | IRStruct -> [('A', "A");  ('V', "V");  ('H', "H")]

let transparency = "B0"
let process = List.map (fun s -> s ^ transparency)

let colors = function
    | RootSegm -> process ["#c217ba"; "#00ffff"; "#5a5b7e"]
    | IRStruct -> process ["#ff00ff"; "#0055FF"; "#FFA000"]

module type ANNOTATION_RULES = sig
    val add_add : char -> Morelib.CSet.t
    val add_rem : char -> Morelib.CSet.t
    val rem_add : char -> Morelib.CSet.t
    val rem_rem : char -> Morelib.CSet.t
end

let cset_of_string str = CSet.of_seq (String.to_seq str)

module RootSegm = struct
    let add_add _ = Morelib.CSet.empty
    let add_rem = function
        | 'Y' -> cset_of_string "NX"
        | 'N' -> cset_of_string "YX"
        | 'X' -> cset_of_string "YN"
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.RootSegm.add_rem: Invalid argument %C" chr
    let rem_add _ = Morelib.CSet.empty
    let rem_rem _ = Morelib.CSet.empty
end

module IRStruct = struct
    let add_add _ = Morelib.CSet.empty
    let add_rem _ = Morelib.CSet.empty
    let rem_add _ = Morelib.CSet.empty
    let rem_rem _ = Morelib.CSet.empty
end

let rules = function
    | RootSegm -> (module RootSegm : ANNOTATION_RULES)
    | IRStruct -> (module IRStruct : ANNOTATION_RULES)
