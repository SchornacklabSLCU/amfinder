(* CastANet - cTable.ml *)

open CExt
open Scanf
open Printf

type table = {
  main : CLevel.t;
  colonization : CNote.t EMatrix.t;
  arb_vesicles : CNote.t EMatrix.t;
  all_features : CNote.t EMatrix.t;
  network_pred : (string * float array EMatrix.t) list;
}

let main_level {main; _} = main

let get_matrix_at_level tbl = function
  | `COLONIZATION -> tbl.colonization
  | `ARB_VESICLES -> tbl.arb_vesicles
  | `ALL_FEATURES -> tbl.all_features

let iter f tbl lvl = EMatrix.iteri f (get_matrix_at_level tbl lvl)

let create ?(main = `COLONIZATION) src =
  let mat = match src with
    | `DIM (r, c) -> EMatrix.init r c (fun _ _ -> CNote.create ())
    | `MAT matrix -> EMatrix.map (fun _ -> CNote.create ()) matrix in
  { main; colonization = mat;
    arb_vesicles = EMatrix.copy mat;
    all_features = EMatrix.copy mat;
    network_pred = [] }

let to_string tbl lvl =
  let elt = get_matrix_at_level tbl lvl in
  EMatrix.to_string ~cast:CNote.to_string elt

let of_string ~main ~col_table ~arb_table ~all_table = 
  let f = EMatrix.of_string ~cast:CNote.of_string in
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
  EMatrix.iter (fun t ->
    let annot = EStringSet.union (CNote.get t `USER) (CNote.get t `HOLD) in
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


