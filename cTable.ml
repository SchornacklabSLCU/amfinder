(* CastANet - cAnnot.ml *)

open CExt
open Scanf
open Printf

let auto_background = ref true

module Rule = struct
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
end

let other = function
  | `COLONIZATION -> `ARB_VESICLES, `ALL_FEATURES
  | `ARB_VESICLES -> `COLONIZATION, `ALL_FEATURES
  | `ALL_FEATURES -> `COLONIZATION, `ARB_VESICLES


let get_rule = function
  | `COLONIZATION -> Rule.Colonization.get
  | `ARB_VESICLES -> Rule.Arb_vesicles.get
  | `ALL_FEATURES -> Rule.All_features.get

type table = {
  colonization : CNote.t EMatrix.t;
  arb_vesicles : CNote.t EMatrix.t;
  all_features : CNote.t EMatrix.t;
(*network_pred : float array array array;*)
}

type changelog = {
  log_user : (CLevel.t * string) list;
  log_lock : (CLevel.t * string) list;
  log_hold : (CLevel.t * string) list;
}

let ensure_not_empty chg =
  if chg.log_user = []
  && chg.log_lock = []
  && chg.log_hold = [] then None
  else Some chg


module Note = struct
  let rec mem chr t = function
    | `USER -> String.contains (CNote.get t `USER) chr
    | `LOCK -> String.contains (CNote.get t `LOCK) chr
    | `HOLD -> String.contains (CNote.get t `HOLD) chr
    | `FULL -> List.exists (mem chr t) [`USER; `LOCK; `HOLD]
    
  let add lvl1 lvl2 chr note =
    let usermode = (lvl1 = lvl2) and extra = String.make 1 chr in
    let log_user, log_lock, log_hold = 
      if usermode then begin
        let old = CNote.get note `USER in
        CNote.set note `USER (EStringSet.union old extra);
        let d = EStringSet.diff extra old in
        if d = "" then [], [], [] else [lvl1, d], [], []
      end else begin
        let old_lock = CNote.get note `LOCK 
        and old_hold = CNote.get note `HOLD in
        let hold, lock = get_rule lvl1 lvl2 extra in
        CNote.set note `LOCK (EStringSet.union old_lock lock);
        CNote.set note `HOLD (EStringSet.union old_hold hold);
        let dl = diff lock old_lock
        and dh = diff hold old_hold in
        EStringSet.([], (if dl = "" then [] else [lvl1, dl]), 
                        (if dh = "" then [] else [lvl1, dh]))
      end
    in {log_user; log_lock; log_hold}
    
  let rem lvl1 lvl2 chr note = 
    let usermode = (lvl1 = lvl2) and del = String.make 1 chr in
    let log_user, log_lock, log_hold =
      if usermode then begin
        let old = CNote.get note `USER in
        CNote.set note `USER (EStringSet.diff old del);
        [lvl1, del], [], []
      end else begin
        let old_lock = CNote.get note `LOCK 
        and old_hold = CNote.get note `HOLD in
        let hold, lock = get_rule lvl1 lvl2 del in
        CNote.set note `LOCK (EStringSet.diff old_lock lock);
        CNote.set note `HOLD (EStringSet.diff old_hold hold);
        [], [lvl2, lock], [lvl2, hold]
      end 
    in {log_user; log_lock; log_hold}
end

let level t = function
  | `COLONIZATION -> t.colonization
  | `ARB_VESICLES -> t.arb_vesicles
  | `ALL_FEATURES -> t.all_features
   
let to_string tbl lvl = 
  let mat = match lvl with
    | `COLONIZATION -> tbl.colonization
    | `ARB_VESICLES -> tbl.arb_vesicles
    | `ALL_FEATURES -> tbl.all_features
  in EMatrix.to_string ~cast:CNote.to_string mat
  
let of_string ~col:x ~arb:y ~all:z = 
  let f = EMatrix.of_string ~cast:CNote.of_string in
  { colonization = f x; arb_vesicles = f y; all_features = f z }

let statistics tbl lvl =
  let mat = match lvl with
    | `COLONIZATION -> tbl.colonization
    | `ARB_VESICLES -> tbl.arb_vesicles
    | `ALL_FEATURES -> tbl.all_features in
  let stats = List.map (fun chr -> chr, ref 0) CLevel.all_chars_list in
  EMatrix.iter (fun note ->
    EStringSet.union (CNote.get note `USER) (CNote.get note `HOLD)
    |> String.iter (fun chr -> incr (List.assoc chr stats))
  ) mat;
  List.map (fun (chr, r) -> chr, !r) stats

module Changelog = struct
  let add ch1 ch2 = {
    log_user = ch1.log_user @ ch2.log_user;
    log_lock = ch1.log_lock @ ch2.log_lock;
    log_hold = ch1.log_hold @ ch2.log_hold;
  }
end

let get table lvl ~r ~c typ =
  let note = (level table lvl).(r).(c) in
  CNote.get note typ

(* An annotation can be added if it:
    - has not already been defined (user).
    - is not forbidden for consistency (lock).
    - is not activated for consistency (hold). *)
let add t lvl1 ~r ~c chr =
  let mat = level t lvl1 in
  if Note.mem chr mat.(r).(c) `FULL then None else (
    let log1 = Note.add lvl1 lvl1 chr mat.(r).(c) in
    let lvl2, lvl3 = other lvl1 in
    let log2 = Note.add lvl1 lvl2 chr (level t lvl2).(r).(c)
    and log3 = Note.add lvl1 lvl3 chr (level t lvl3).(r).(c) in
    ensure_not_empty Changelog.(add (add log1 log2) log3)
  )

(* An annotation can be removed only if it is part of the <user> field.  *)
let remove t lvl1 ~r ~c chr =
  let mat = level t lvl1 in
  if Note.mem chr mat.(r).(c) `USER then (
    let log1 = Note.rem lvl1 lvl1 chr mat.(r).(c) in
    let lvl2, lvl3 = other lvl1 in
    let log2 = Note.rem lvl1 lvl2 chr (level t lvl2).(r).(c)
    and log3 = Note.rem lvl1 lvl3 chr (level t lvl3).(r).(c) in
    ensure_not_empty Changelog.(add (add log1 log2) log3)
  ) else None

(* TODO: exports simplified tables for Python work. *)
let save t zip =
  let och = Zip.open_out zip in
  let dat = to_string t `COLONIZATION in
  Zip.add_entry dat och "colonization.mldata" ~comment:(Digest.string dat);
  let dat = to_string t `ARB_VESICLES in
  Zip.add_entry dat och "arb_vesicles.mldata" ~comment:(Digest.string dat);
  let dat = to_string t `ALL_FEATURES in
  Zip.add_entry dat och "all_features.mldata" ~comment:(Digest.string dat);
  Zip.close_out och

let load src =
  try
    assert (Sys.file_exists src);
    let ich = Zip.open_in src in
    let xe = Zip.find_entry ich "colonization.mldata"
    and ye = Zip.find_entry ich "arb_vesicles.mldata"
    and ze = Zip.find_entry ich "all_features.mldata" in
    let xd = Zip.read_entry ich xe
    and yd = Zip.read_entry ich ye
    and zd = Zip.read_entry ich ze in
    assert (Digest.string xd = xe.Zip.comment);
    assert (Digest.string yd = ye.Zip.comment);
    assert (Digest.string zd = ze.Zip.comment);
    Zip.close_in ich;
    Some (of_string ~col:xd ~arb:yd ~all:zd)
  with Assert_failure _ | Zip.Error _ | Sys_error _ -> None

let create src =
  let mat = match src with
    | `DIM (r, c) -> EMatrix.init r c (fun _ _ -> CNote.create ())
    | `MAT matrix -> EMatrix.map (fun _ -> CNote.create ()) matrix in
  { colonization = mat;
    arb_vesicles = EMatrix.copy mat;
    all_features = EMatrix.copy mat }


let iter f table = function
  | `COLONIZATION -> EMatrix.iteri f table.colonization
  | `ARB_VESICLES -> EMatrix.iteri f table.arb_vesicles
  | `ALL_FEATURES -> EMatrix.iteri f table.all_features
