(* CastANet - cAnnot.ml *)

open CExt
open Scanf
open Printf

let auto_background = ref true

module Rule = struct
  module Colonization = struct
    let other = E_StringSet.diff "YNX"
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
    let other = E_StringSet.diff "AVNX"
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
    let other = E_StringSet.diff "AVIEHRX"
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

let get_rule = function
  | `COLONIZATION -> Rule.Colonization.get
  | `ARB_VESICLES -> Rule.Arb_vesicles.get
  | `ALL_FEATURES -> Rule.All_features.get

type level = [
  | `COLONIZATION (* colonized vs non-colonized vs background                 *)
  | `ARB_VESICLES (* [arbuscules, vesicles] vs non-colonized vs background    *)
  | `ALL_FEATURES (* [ERH, [root, [arb, ves, IRH, hyphopodia]]] vs background *)
]

let levels = [`COLONIZATION; `ARB_VESICLES; `ALL_FEATURES]

type note = {
  mutable user : string;
  mutable lock : string;
  mutable hold : string;
(*mutable pred : string; Annotations given by the prediction. *)
}

type note_type = [`USER | `HOLD | `LOCK]

type table = {
  colonization : note array array;
  arb_vesicles : note array array;
  all_features : note array array;
(*network_pred : float array array array;*)
}

type changelog = {
  log_user : (level * string) list;
  log_lock : (level * string) list;
  log_hold : (level * string) list;
}

module Note = struct
  let create () = {user = ""; lock = ""; hold = ""}

  let to_string {user; lock; hold} = sprintf "%s %s %s" user lock hold
  let of_string s = sscanf s "%[A-Z] %[A-Z] %[A-Z]" 
    (fun x y z -> {user = x; lock = y; hold = z})

  let get t = function
    | `USER -> t.user
    | `LOCK -> t.lock
    | `HOLD -> t.hold

  let rec mem chr t = function
    | `USER -> String.contains t.user chr
    | `LOCK -> String.contains t.lock chr
    | `HOLD -> String.contains t.hold chr
    | `FULL -> List.exists (mem chr t) [`USER; `LOCK; `HOLD]
    
  let add lvl1 lvl2 chr note =
    let usermode = (lvl1 = lvl2) and extra = String.make 1 chr in
    let log_user, log_lock, log_hold = 
      if usermode then begin
        let old = note.user in
        note.user <- E_StringSet.union old extra;
        [lvl1, E_StringSet.diff extra old], [], []
      end else begin
        let old_lock = note.lock and old_hold = note.hold in
        let hold, lock = get_rule lvl1 lvl2 extra in
        note.lock <- E_StringSet.union old_lock lock;
        note.hold <- E_StringSet.union old_hold hold;
        E_StringSet.([], [lvl1, diff lock old_lock], [lvl1, diff hold old_hold])
      end
    in {log_user; log_lock; log_hold}
    
  let rem lvl1 lvl2 chr note = 
    let usermode = (lvl1 = lvl2) and del = String.make 1 chr in
    let log_user, log_lock, log_hold =
      if usermode then begin
        let old = note.user in
        note.user <- E_StringSet.diff old del;
        [lvl1, del], [], []
      end else begin
        let old_lock = note.lock and old_hold = note.hold in
        let hold, lock = get_rule lvl1 lvl2 del in
        note.lock <- E_StringSet.diff old_lock lock;
        note.hold <- E_StringSet.diff old_hold hold;
        [], [lvl2, lock], [lvl2, hold]
      end 
    in {log_user; log_lock; log_hold}
end


module Level = struct
  let all = [`COLONIZATION; `ARB_VESICLES; `ALL_FEATURES]
  let other = function
    | `COLONIZATION -> `ARB_VESICLES, `ALL_FEATURES
    | `ARB_VESICLES -> `COLONIZATION, `ALL_FEATURES
    | `ALL_FEATURES -> `COLONIZATION, `ARB_VESICLES

  module Symbols = struct
    let colonization = ['Y'; 'N'; 'X']
    let arb_vesicvle = ['A'; 'V'; 'N'; 'X']
    let all_features = ['A'; 'V'; 'I'; 'E'; 'H'; 'R'; 'X']
  end
  
  module Colors = struct
    let colonization = ["#80b3ff"; "#bec8b7"; "#ffaaaa"]
    let arb_vesicles = ["#80b3ff"; "#afe9c6"; "#bec8b7"; "#ffaaaa"]
    let all_features = ["#80b3ff"; "#afe9c6"; "#ffeeaa"; "#eeaaff";
                        "#ffb380"; "#bec8b7"; "#ffaaaa" ]
  end

  let statistics matrix =
    let stats = List.map (fun chr -> chr, ref 0) in
    EMatrix.iter (fun note ->
      EStringSet.union note.user note.hold
      |> String.iter (fun chr -> incr (List.assoc chr stats))
    ) matrix;
    List.map (fun (chr, r) -> chr, !r) stats
end

let code_list = function
  | `COLONIZATION -> Level.Symbols.colonization
  | `ARB_VESICLES -> Level.Symbols.arb_vesicles
  | `ALL_FEATURES -> Level.Symbols.all_features  

let colors = function
  | `COLONIZATION -> Level.Colors.colonization
  | `ARB_VESICLES -> Level.Colors.arb_vesicles
  | `ALL_FEATURES -> Level.Colors.all_features  

module Table = struct
  let level t = function
    | `COLONIZATION -> t.colonization
    | `ARB_VESICLES -> t.arb_vesicles
    | `ALL_FEATURES -> t.all_features
    
  let string_of_matrix t =
    Array.map (Array.map Note.to_string) t
    |> Array.map Array.to_list
    |> Array.map (String.concat "\t")
    |> Array.to_list
    |> String.concat "\n"

  let matrix_of_string s =
    String.split_on_char '\n' s
    |> Array.of_list
    |> Array.map (String.split_on_char '\t')
    |> Array.map Array.of_list
    |> Array.map (Array.map Note.of_string)
    
  let to_string t = function
    | `COLONIZATION -> string_of_matrix t.colonization
    | `ARB_VESICLES -> string_of_matrix t.arb_vesicles
    | `ALL_FEATURES -> string_of_matrix t.all_features
    
  let of_string ~col:x ~arb:y ~all:z = {
    colonization = matrix_of_string x;
    arb_vesicles = matrix_of_string y;
    all_features = matrix_of_string z }
end


let statistics t = function
  | `COLONIZATION -> string_of_matrix t.colonization
  | `ARB_VESICLES -> string_of_matrix t.arb_vesicles
  | `ALL_FEATURES -> string_of_matrix t.all_features


module Changelog = struct
  let add ch1 ch2 = {
    log_user = ch1.log_user @ ch2.log_user;
    log_lock = ch1.log_lock @ ch2.log_lock;
    log_hold = ch1.log_hold @ ch2.log_hold;
  }
end

let get table lvl ~r ~c typ =
  let note = (Table.level table lvl).(r).(c) in
  Note.get note typ

(* An annotation can be added if it:
    - has not already been defined (user).
    - is not forbidden for consistency (lock).
    - is not activated for consistency (hold). *)
let add t lvl1 ~r ~c chr =
  let mat = Table.level t lvl1 in
  if Note.mem chr mat.(r).(c) `FULL then None else (
    let log1 = Note.add lvl1 lvl1 chr mat.(r).(c) in
    let lvl2, lvl3 = Level.other lvl1 in
    let log2 = Note.add lvl1 lvl2 chr (Table.level t lvl2).(r).(c)
    and log3 = Note.add lvl1 lvl3 chr (Table.level t lvl3).(r).(c) in
    Some Changelog.(add (add log1 log2) log3)
  )

(* An annotation can be removed only if it is part of the <user> field.  *)
let remove t lvl1 ~r ~c chr =
  let mat = Table.level t lvl1 in
  if Note.mem chr mat.(r).(c) `USER then (
    let log1 = Note.rem lvl1 lvl1 chr mat.(r).(c) in
    let lvl2, lvl3 = Level.other lvl1 in
    let log2 = Note.rem lvl1 lvl2 chr (Table.level t lvl2).(r).(c)
    and log3 = Note.rem lvl1 lvl3 chr (Table.level t lvl3).(r).(c) in
    Some Changelog.(add (add log1 log2) log3)
  ) else None

(* TODO: exports simplified tables for Python work. *)
let save t zip =
  let och = Zip.open_out zip in
  let dat = Table.to_string t `COLONIZATION in
  Zip.add_entry dat och "colonization.mldata" ~comment:(Digest.string dat);
  let dat = Table.to_string t `ARB_VESICLES in
  Zip.add_entry dat och "arb_vesicles.mldata" ~comment:(Digest.string dat);
  let dat = Table.to_string t `ALL_FEATURES in
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
    Some (Table.of_string ~col:xd ~arb:yd ~all:zd)
  with Assert_failure _ | Zip.Error _ | Sys_error _ -> None

let create = function
  | `DIM (r, c) -> EMatrix.init r c (fun _ _ -> Note.create ())
  | `MAT matrix -> EMatrix.map (fun _ -> Note.create ()) matrix

let statistics table = function
  | `COLONIZATION -> Level.statistics table.colonization
  | `ARB_VESICLES -> Level.statistics table.arb_vesicles
  | `ALL_FEATURES -> Level.statistics table.all_features
  
let iter table table f = function
  | `COLONIZATION -> EMatrix.iter f table.colonization
  | `ARB_VESICLES -> EMatrix.iter f table.arb_vesicles
  | `ALL_FEATURES -> EMatrix.iter f table.all_features
