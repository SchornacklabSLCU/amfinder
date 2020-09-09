(* CastANet - cTable.ml *)

open CExt
open Scanf
open Printf

type table = {
  main : CLevel.t;
  colonization : CTile.t Ext_Matrix.t;
  arb_vesicles : CTile.t Ext_Matrix.t;
  all_features : CTile.t Ext_Matrix.t;
  network_pred : (string * float array Ext_Matrix.t) list;
}

let main_level {main; _} = main

let get_matrix_at_level tbl = function
  | `COLONIZATION -> tbl.colonization
  | `ARB_VESICLES -> tbl.arb_vesicles
  | `ALL_FEATURES -> tbl.all_features

let iter f tbl lvl = Ext_Matrix.iteri f (get_matrix_at_level tbl lvl)

let create ?(main = `COLONIZATION) src =
  let mat () = match src with
    | `DIM (r, c) -> Ext_Matrix.init r c (fun _ _ -> CTile.create ())
    | `MAT matrix -> Ext_Matrix.map (fun _ -> CTile.create ()) matrix in
  { main; colonization = mat ();
    arb_vesicles = mat ();
    all_features = mat ();
    network_pred = [] }

let to_string tbl lvl =
  let elt = get_matrix_at_level tbl lvl in
  Ext_Matrix.to_string ~cast:CTile.to_string elt

let of_string ~main ~col_table ~arb_table ~all_table = 
  let f = Ext_Matrix.of_string ~cast:CTile.of_string in
  { main; colonization = f col_table;
    arb_vesicles = f arb_table;
    all_features = f all_table;
    network_pred = [] }

let load zip =
  let unsafe_load zip =
    assert (Sys.file_exists zip);
    let ich = Zip.open_in zip in
    let col_entry = Zip.find_entry ich "colonization.mldata"
    and arb_entry = Zip.find_entry ich "arb_vesicles.mldata"
    and all_entry = Zip.find_entry ich "all_features.mldata" in
    let main = if col_entry.Zip.extra = "main" then `COLONIZATION
          else if arb_entry.Zip.extra = "main" then `ARB_VESICLES
          else if all_entry.Zip.extra = "main" then `ALL_FEATURES
          else assert false in
    let col_table = Zip.read_entry ich col_entry
    and arb_table = Zip.read_entry ich arb_entry
    and all_table = Zip.read_entry ich all_entry in
    assert (Digest.string col_table = col_entry.Zip.comment);
    assert (Digest.string arb_table = arb_entry.Zip.comment);
    assert (Digest.string all_table = all_entry.Zip.comment);
    Zip.close_in ich;
    Some (of_string ~main ~col_table ~arb_table ~all_table)
  in try unsafe_load zip with _ -> None

let statistics tbl lvl =
  let stats = List.map (fun chr -> chr, ref 0) (CAnnot.char_list lvl) in
  Ext_Matrix.iter (fun t ->
    let annot = EStringSet.union (CTile.get t `USER) (CTile.get t `HOLD) in
    String.iter (fun c -> incr (List.assoc c stats)) annot
  ) (get_matrix_at_level tbl lvl);
  List.map (fun (chr, r) -> chr, !r) stats

type export_flag = [
  | `USER_ANNOT_ONLY
  | `AUTO_BACKGROUND
  | `MAIN_LEVEL_ONLY
  | `LEVEL of CLevel.t
  | `PREDICTION of string
  | `PRED_THRESHOLD of float
  | `MIN_STDEV of float
  | `BEST_PREDICTION
  | `EXPORT_STATISTICS
]

let save 
 ?(export = false) 
 ?(flags = [`AUTO_BACKGROUND; `MAIN_LEVEL_ONLY]) t zip =
  let d1 = to_string t `COLONIZATION
  and d2 = to_string t `ARB_VESICLES
  and d3 = to_string t `ALL_FEATURES in
  let c1 = Digest.string d1
  and c2 = Digest.string d2
  and c3 = Digest.string d3 in
  let e1, e2, e3 = match main_level t with
    | `COLONIZATION -> Some "main", None, None
    | `ARB_VESICLES -> None, Some "main", None
    | `ALL_FEATURES -> None, None, Some "main" in
  let och = Zip.open_out zip in
  Zip.add_entry d1 och "colonization.mldata" ~comment:c1 ?extra:e1;
  Zip.add_entry d2 och "arb_vesicles.mldata" ~comment:c2 ?extra:e2;
  Zip.add_entry d3 och "all_features.mldata" ~comment:c3 ?extra:e3;
  (* TODO: insert export here. *)
  Zip.close_out och

(* FIXME: Get may no be used at all. *)
let get tbl lvl ~r ~c = (get_matrix_at_level tbl lvl).(r).(c)

let get_all tbl ~r ~c = List.map (fun lvl -> lvl, get tbl lvl ~r ~c) CLevel.flags

(* FIXME: The two functions below look very similar and may be combined. *)
let add tbl lvl ~r ~c chr =
  let chr = Char.uppercase_ascii chr in
  if String.contains (CAnnot.chars lvl) chr then (
    let mat = get_matrix_at_level tbl lvl in
    (* In this case, adds the annotations and propagate constraints. *)
    if lvl = main_level tbl then (
      let user = String.make 1 chr
      and hold, lock = CAnnot.rule lvl lvl (`CHR chr) in
      let tile = mat.(r).(c) in
      CLog.info "At level %s, adding user=%S hold=%S lock=%S"
        (CLevel.to_string lvl) user hold lock;
      CTile.set tile `USER (`CHR chr);
      CTile.set tile `LOCK (`STR lock);
      CTile.set tile `HOLD (`STR hold);
      let log = CTile.make
        ~user:(`STR user)
        ~lock:(`STR lock)
        ~hold:(`STR hold) () in
      List.fold_right
        (fun alt log -> (* propagates constraints. *)
          (* TODO annotations added by the user on other layers. *)
          let alt_tile = (get_matrix_at_level tbl alt).(r).(c) in
          let hold, lock = CAnnot.rule lvl alt (`CHR chr) in
          CLog.info "At level %s, hold=%S lock=%S" (CLevel.to_string alt) hold lock;
          CTile.set alt_tile `LOCK (`STR lock);
          CTile.set alt_tile `HOLD (`STR hold);
          let more_log = CTile.make ~lock:(`STR lock) ~hold:(`STR hold) () in
          (alt, more_log) :: log
        ) (CLevel.others lvl) [lvl, log]
    (* In this case, just adds the annotations. No constraints propagation. *)
    ) else (CTile.add mat.(r).(c) `USER (`CHR chr); [])
  ) else [] (* Invalid character. *)

let remove tbl lvl ~r ~c chr =
  let chr = Char.uppercase_ascii chr in
  if String.contains (CAnnot.chars lvl) chr then (
    let mat = get_matrix_at_level tbl lvl in
    if lvl = main_level tbl then (
      let tile = mat.(r).(c) in
      let old_user = CTile.get tile `USER
      and old_lock = CTile.get tile `LOCK
      and old_hold = CTile.get tile `HOLD in
      CTile.remove tile `USER (`CHR chr);
      let user = CTile.get tile `USER in
      (* Hold and lock from all remaining annotations. *)
      let hold, lock = CAnnot.rule lvl lvl (`STR user) in
      CTile.set tile `LOCK (`STR lock);
      CTile.set tile `HOLD (`STR hold);
      let log = CTile.create () in
      CTile.add log `USER (`STR (EStringSet.diff user old_user));
      CTile.add log `LOCK (`STR (EStringSet.diff lock old_lock));
      CTile.add log `HOLD (`STR (EStringSet.diff hold old_hold));
      List.fold_right
        (fun alt log -> (* propagates constraints. *)
          (* TODO annotations added by the user on other layers. *)
          let alt_tile = (get_matrix_at_level tbl alt).(r).(c) in
          let old_lock = CTile.get alt_tile `LOCK
          and old_hold = CTile.get alt_tile `HOLD in
          let hold, lock = CAnnot.rule lvl alt (`STR user) in  
          CTile.set alt_tile `LOCK (`STR lock);
          CTile.set alt_tile `HOLD (`STR hold);
          let more_log = CTile.create () in
          CTile.add more_log `LOCK (`STR (EStringSet.diff lock old_lock));
          CTile.add more_log `HOLD (`STR (EStringSet.diff hold old_hold));
          (alt, more_log) :: log
        ) (CLevel.others lvl) [lvl, log]
    ) else (CTile.remove mat.(r).(c) `USER (`CHR chr); [])
  ) else [] (* Invalid character. *)

let is_valid tbl ~r ~c =
  try
    ignore (get_matrix_at_level tbl `COLONIZATION).(r).(c);
    true
  with _ -> false

let is_empty tbl lvl ~r ~c =
  try
    let f = CTile.is_empty (get_matrix_at_level tbl lvl).(r).(c) in
    f `USER || f `HOLD
  with _ -> invalid_arg "CTable.is_empty"

let mem tbl lvl ~r ~c elt =
  try
    let f = CTile.mem (get_matrix_at_level tbl lvl).(r).(c) in
    f `USER elt || f `HOLD elt
  with _ -> invalid_arg "CTable.mem"







