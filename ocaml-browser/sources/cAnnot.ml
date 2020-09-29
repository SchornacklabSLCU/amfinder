(* CastANet - cAnnot.ml *)

open Morelib

type lock = string
type hold = string

module type S = sig
  val diff : string -> string
  val get : CLevel.t -> char -> hold * lock
end

let generator ~col ~arb ~all str =
  let module M = struct
    let diff s = if s = "" then str else StringSet.diff str s
    let get = function
      | `COLONIZATION -> col
      | `ARB_VESICLES -> arb
      | `ALL_FEATURES -> all
  end in (module M : S)

let m_colonization = 
  let col = function
    | 'Y' -> "", "NX"
    | 'N' -> "", "YX"
    |  _  -> "", "YN"
  and arb = function
    | 'Y' -> "", "NX"
    | 'N' -> "N", "AVX"
    |  _  -> "X", "AVN"
  and all = function
    | 'Y' -> "", "X"
    | 'N' -> "R", "AVIEHX"
    |  _  -> "X", "AVIEHR"
  in generator ~col ~arb ~all "YNX"

let m_arb_vesicles =
  let col = function
    | 'A' | 'V' -> "Y", "NX"
    | 'N' -> "N", "YX"
    |  _  -> "X", "YN"
  and arb = function
    | 'A' | 'V' -> "", "NX"
    | 'N' -> "", "AVX"
    |  _  -> "", "AVN"
  and all = function
    | 'A' -> "AR", "X"
    | 'V' -> "VR", "X"
    | 'N' -> "R", "AVIEHX"
    |  _  -> "X", "AVIEHR"
  in generator ~col ~arb ~all "AVNX"

let m_all_features =
  let col = function
    | 'A' | 'V' | 'I' | 'E' | 'H' -> "Y", "NX"
    | 'R' -> "", "X"
    |  _  -> "X", "YN"
  and arb = function
    | 'A' -> "A", "NX"
    | 'V' -> "V", "NX"
    | 'I' | 'E' | 'H' -> "", "NX"
    | 'R' -> "", "X"
    |  _  -> "X", "AVN"
  and all = function
    | 'A' | 'V' | 'I' | 'H' -> "R", "X"
    | 'E' -> "", "X"
    | 'R' -> "", "X"
    |  _  -> "", "AVIEHR"
  in generator ~col ~arb ~all "AVIEHRX"

let get = function
  | `COLONIZATION -> m_colonization
  | `ARB_VESICLES -> m_arb_vesicles
  | `ALL_FEATURES -> m_all_features

let chars lvl = let open (val (get lvl) : S) in diff ""

let char_list lvl = Text.explode (chars lvl)

(* Not hardcoded, should the list change in the future. *)
let all_chars =
  let col = chars `COLONIZATION
  and arb = chars `ARB_VESICLES
  and all = chars `ALL_FEATURES in
  StringSet.(union (union col arb) all)

let all_chars_list = Text.explode all_chars

let rule_of_char lvl = let open (val (get lvl) : S) in get

let rule_of_string lv1 lv2 str =
  Seq.fold_left (fun (x1, y1) chr ->
    let x2, y2 = rule_of_char lv1 lv2 chr in
    StringSet.(union x1 x2, union y1 y2)
  ) ("", "") (String.to_seq str)

let rule lv1 lv2 = function
  | `CHR chr -> rule_of_char lv1 lv2 chr
  | `STR str -> rule_of_string lv1 lv2 str

let others elt lvl =
  let str = match elt with
    | `CHR chr -> String.make 1 chr
    | `STR str -> str in 
  let open (val (get lvl) : S) in diff (String.uppercase_ascii str)

let rec mem elt lvl = 
  match elt with
  | `CHR chr -> String.contains (chars lvl) (Char.uppercase_ascii chr)
  | `STR str -> List.for_all (fun c -> mem (`CHR c) lvl) (Text.explode str)

