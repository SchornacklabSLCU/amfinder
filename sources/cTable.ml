(* CastANet - cTable.ml *)

open CExt
open Scanf
open Printf

type table = {
  main : CLevel.t;
  colonization : CMask.tile Ext_Matrix.t;
  arb_vesicles : CMask.tile Ext_Matrix.t;
  all_features : CMask.tile Ext_Matrix.t;
  network_pred : CPyTable.pytable list;
}

let main_level {main; _} = main

let get_matrix_at_level tbl = function
  | `COLONIZATION -> tbl.colonization
  | `ARB_VESICLES -> tbl.arb_vesicles
  | `ALL_FEATURES -> tbl.all_features

let iter f tbl lvl = Ext_Matrix.iteri f (get_matrix_at_level tbl lvl)

let create ?(main = `COLONIZATION) src =
  let mat () = match src with
    | `DIM (r, c) -> Ext_Matrix.init r c (fun _ _ -> CMask.create ())
    | `MAT matrix -> Ext_Matrix.map (fun _ -> CMask.create ()) matrix in
  { main; colonization = mat ();
    arb_vesicles = mat ();
    all_features = mat ();
    network_pred = [] }

let to_string tbl lvl =
  let elt = get_matrix_at_level tbl lvl in
  Ext_Matrix.to_string ~cast:CMask.to_string elt

let of_string ~main ~col_table ~arb_table ~all_table ~predictions () = 
  let f = Ext_Matrix.of_string ~cast:CMask.of_string in
  { main; colonization = f col_table;
    arb_vesicles = f arb_table;
    all_features = f all_table;
    network_pred = predictions }


(* Not used at the moment. ---
module Method = struct
  let threshold hdr dat =
    List.fold_left2 (fun s chr z ->
      if z > 0.9 then sprintf "%s%c" s chr else s
    ) "" hdr dat |> (fun a -> `STR a)

  let best hdr dat =
    List.fold_left2 (fun ((x, y) as m) chr z ->
      if z > y then (chr, z) else m
    ) ('.', 0.0) hdr dat |> (fun (a, _) -> `CHR a)
end *)

(* Function to load old tsv files that are not part of a zip!
 * Will be removed at some point. *)
let load_tsv tsv =
  let pytable = CPyTable.load tsv in
  let nr, nc = Ext_Matrix.dim (CPyTable.matrix pytable) in
  let create () = Ext_Matrix.init nr nc (fun _ _ -> CMask.create ()) in
  Some { main = `COLONIZATION; 
    colonization = create ();
    arb_vesicles = create ();
    all_features = create ();
    network_pred = [pytable] }


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
    let predictions = [] in (* TODO replace by a proper loading function! *)
    Some (of_string ~main ~col_table ~arb_table ~all_table ~predictions ())
  in try unsafe_load zip with _ -> None

let statistics tbl lvl =
  let stats = List.map (fun chr -> chr, ref 0) (CAnnot.char_list lvl) in
  Ext_Matrix.iter (fun t ->
    let annot = Ext_StringSet.union (CMask.get t `USER) (CMask.get t `HOLD) in
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
  (* Saving annotation tables. *)
  Zip.add_entry d1 och "colonization.mldata" ~comment:c1 ?extra:e1;
  Zip.add_entry d2 och "arb_vesicles.mldata" ~comment:c2 ?extra:e2;
  Zip.add_entry d3 och "all_features.mldata" ~comment:c3 ?extra:e3;
  (* Saving CNN-generated predictions. *)
  List.iter (fun pt ->
    let tsv = CPyTable.to_string pt in 
    let out = sprintf "predictions/%s.tsv" (CPyTable.label pt) in
    Zip.add_entry tsv och out ~comment:(Digest.string tsv);
  ) t.network_pred;
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
      CMask.set tile `USER (`CHR chr);
      CMask.set tile `LOCK (`STR lock);
      CMask.set tile `HOLD (`STR hold);
      let log = CMask.make
        ~user:(`STR user)
        ~lock:(`STR lock)
        ~hold:(`STR hold) () in
      List.fold_right
        (fun alt log -> (* propagates constraints. *)
          (* TODO annotations added by the user on other layers. *)
          let alt_tile = (get_matrix_at_level tbl alt).(r).(c) in
          let hold, lock = CAnnot.rule lvl alt (`CHR chr) in
          CLog.info "At level %s, hold=%S lock=%S" (CLevel.to_string alt) hold lock;
          CMask.set alt_tile `LOCK (`STR lock);
          CMask.set alt_tile `HOLD (`STR hold);
          let more_log = CMask.make ~lock:(`STR lock) ~hold:(`STR hold) () in
          (alt, more_log) :: log
        ) (CLevel.others lvl) [lvl, log]
    (* In this case, just adds the annotations. No constraints propagation. *)
    ) else (CMask.add mat.(r).(c) `USER (`CHR chr); [])
  ) else [] (* Invalid character. *)

let remove tbl lvl ~r ~c chr =
  let chr = Char.uppercase_ascii chr in
  if String.contains (CAnnot.chars lvl) chr then (
    let mat = get_matrix_at_level tbl lvl in
    if lvl = main_level tbl then (
      let tile = mat.(r).(c) in
      let old_user = CMask.get tile `USER
      and old_lock = CMask.get tile `LOCK
      and old_hold = CMask.get tile `HOLD in
      CMask.remove tile `USER (`CHR chr);
      let user = CMask.get tile `USER in
      (* Hold and lock from all remaining annotations. *)
      let hold, lock = CAnnot.rule lvl lvl (`STR user) in
      CMask.set tile `LOCK (`STR lock);
      CMask.set tile `HOLD (`STR hold);
      let log = CMask.create () in
      CMask.add log `USER (`STR (Ext_StringSet.diff user old_user));
      CMask.add log `LOCK (`STR (Ext_StringSet.diff lock old_lock));
      CMask.add log `HOLD (`STR (Ext_StringSet.diff hold old_hold));
      List.fold_right
        (fun alt log -> (* propagates constraints. *)
          (* TODO annotations added by the user on other layers. *)
          let alt_tile = (get_matrix_at_level tbl alt).(r).(c) in
          let old_lock = CMask.get alt_tile `LOCK
          and old_hold = CMask.get alt_tile `HOLD in
          let hold, lock = CAnnot.rule lvl alt (`STR user) in  
          CMask.set alt_tile `LOCK (`STR lock);
          CMask.set alt_tile `HOLD (`STR hold);
          let more_log = CMask.create () in
          CMask.add more_log `LOCK (`STR (Ext_StringSet.diff lock old_lock));
          CMask.add more_log `HOLD (`STR (Ext_StringSet.diff hold old_hold));
          (alt, more_log) :: log
        ) (CLevel.others lvl) [lvl, log]
    ) else (CMask.remove mat.(r).(c) `USER (`CHR chr); [])
  ) else [] (* Invalid character. *)

let is_valid tbl ~r ~c =
  try
    ignore (get_matrix_at_level tbl `COLONIZATION).(r).(c);
    true
  with _ -> false

let is_empty tbl lvl ~r ~c =
  try
    let f = CMask.is_empty (get_matrix_at_level tbl lvl).(r).(c) in
    f `USER && f `HOLD
  with _ -> invalid_arg "CTable.is_empty"

let mem tbl lvl ~r ~c elt =
  try
    let f = CMask.mem (get_matrix_at_level tbl lvl).(r).(c) in
    f `USER elt || f `HOLD elt
  with _ -> invalid_arg "CTable.mem"







