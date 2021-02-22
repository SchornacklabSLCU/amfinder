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

type level = bool

let col = true
let myc = false

let col_header = ['Y'; 'N'; 'X']
let myc_header = ['A'; 'V'; 'H'; 'I']

let is_col x = x 
let is_myc x = not x

let to_header = function
    | true  -> col_header
    | false -> myc_header

let to_string = function
    | true  -> "col"
    | false -> "myc"

let of_string str =
    match String.lowercase_ascii str with
    | "col" -> true
    | "myc" -> false
    | unknown -> AmfLog.error ~code:Err.Level.unknown_level
        "(AmfLevel.of_string) Wrong annotation level %S" unknown

let of_header t =
    let t = List.map Char.uppercase_ascii t in
    if t = col_header then true else
    if t = myc_header then false else
    AmfLog.error ~code:Err.Level.invalid_level_header
        "(AmfLevel.of_header) Malformed table header"

let chars lvl = CSet.of_list (to_header lvl)

let char_index lvl chr = to_header lvl
    |> List.to_seq
    |> String.of_seq
    |> (fun str -> String.index str chr)

let all_chars_list = CSet.elements (CSet.union (chars true) (chars false))

let all = [true; false]
let lowest = true
let highest = false

let others = function
    | true  -> [false]
    | false -> [true]

let symbols = function
    | true  -> ["Colonised"; "Non-colonised"; "Background"]
    | false -> ["Arbuscule"; "Vesicle"; "Hyphopodium"; "Hypha"]

let icon_text = function
    | true  -> List.combine col_header ["M+"; "M−"; "×"]
    | false -> [('A', "A");  ('V', "V");  ('H', "H"); ('I', "IH")]

let transparency = "B0"
let process = List.map (fun s -> s ^ transparency)

let colors = function
    | true  -> process ["#0099FF"; "#e8c775"; "#f0f0f0"]
    | false -> process ["#0055FF"; "#FF00FF"; "#31FF12"; "#FFA000"]

let tip = function
    | 'Y' -> "Colonized root section (keyboard: Y or +)"
    | 'N' -> "Non-colonized root section (keyboard: N or -)"
    | 'X' -> "Non-root tile (keyboard: X)"
    | 'A' -> "Arbuscule (keyboard: A)"
    | 'V' -> "Vesicle (keyboard: V)"
    | 'H' -> "Hyphopodium (keyboard: H)"
    | 'I' -> "Intraradical hypha (keyboard: I)"
    |  _  -> assert false



module type ANNOTATION_RULES = sig
    val add_add : char -> CSet.t
    val add_rem : char -> CSet.t
    val rem_add : char -> CSet.t
    val rem_rem : char -> CSet.t
end

let cset_of_string str = CSet.of_seq (String.to_seq str)

module RootSegm = struct
    let add_add _ = CSet.empty
    let add_rem = function
        | 'Y' -> cset_of_string "NX"
        | 'N' -> cset_of_string "YX"
        | 'X' -> cset_of_string "YN"
        | chr -> AmfLog.error ~code:Err.invalid_argument 
            "AmfLevel.true.add_rem: Invalid argument %C" chr
    let rem_add _ = CSet.empty
    let rem_rem _ = CSet.empty
end

module IRStruct = struct
    let add_add _ = CSet.empty
    let add_rem _ = CSet.empty
    let rem_add _ = CSet.empty
    let rem_rem _ = CSet.empty
end

let rules = function
    | true  -> (module RootSegm : ANNOTATION_RULES)
    | false -> (module IRStruct : ANNOTATION_RULES)
