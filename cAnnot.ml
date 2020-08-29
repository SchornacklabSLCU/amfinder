(* CastANet - cAnnot.ml *)

(* open CExt *)
open Scanf
open Printf

let auto_background = ref true

(* Operations on string sets. *)
module StringSet = struct
  let sort s = String.to_seq s
    |> List.of_seq
    |> List.sort Char.compare
    |> List.to_seq
    |> String.of_seq
  (* union "AVI" "IEHA" returns "AEHIV" *)
  let union s1 s2 =
    let res = ref s2 in
    String.iter (fun chr -> 
      if not (String.contains s2 chr) then
        res := sprintf "%s%c" !res chr
    ) s1;
    sort !res
  (* inter "AVI" "IEHA" returns "AI". *)   
  let inter s1 s2 =
    let res = ref "" in
    String.iter (fun chr ->
      if String.contains s2 chr then 
        res := sprintf "%s%c" !res chr
    ) s1;
    sort !res
  (* diff "AVI" "IEHA" returns "V". *)
  let diff s1 s2 =
    let res = ref "" in 
    String.iter (fun chr ->
      if not (String.contains s2 chr) then
        res := sprintf "%s%c" !res chr
    ) s1;
    sort !res
end


module Rule = struct
  module Colonization = struct
    let all = ["Y"; "N"; "X"]
    let other s = List.filter ((<>) s) all |> String.concat ""
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
    let all = ["A"; "V"; "N"; "X"]
    let other s = List.filter ((<>) s) all |> String.concat ""
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
    let all = ["A"; "V"; "I"; "E"; "H"; "R"; "X"]
    let other s = List.filter ((<>) s) all |> String.concat ""
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

let code_list = function
  | `COLONIZATION -> Rule.Colonization.all
  | `ARB_VESICLES -> Rule.Arb_vesicles.all
  | `ALL_FEATURES -> Rule.All_features.all  

type level = [
  | `COLONIZATION (* colonized vs non-colonized vs background                 *)
  | `ARB_VESICLES (* [arbuscules, vesicles] vs non-colonized vs background    *)
  | `ALL_FEATURES (* [ERH, [root, [arb, ves, IRH, hyphopodia]]] vs background *)
]

module Level = struct
  let all = [`COLONIZATION; `ARB_VESICLES; `ALL_FEATURES]
  let other elt = List.filter ((<>) elt) all
end

type note = {
  mutable user : string;
  mutable lock : string;
  mutable hold : string;
(*mutable pred : string; Annotations given by the prediction. *)
}

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

module Table = struct
  let level t = function
    | `COLONIZATION -> t.colonization
    | `ARB_VESICLES -> t.arb_vesicles
    | `ALL_FEATURES -> t.all_features
end


module Note = struct
  let make () = {user = ""; lock = ""; hold = ""}

  let layer t = function
    | `USER -> t.user
    | `LOCK -> t.lock
    | `HOLD -> t.hold

  let rec mem chr t = function
    | `USER -> String.contains t.user chr
    | `LOCK -> String.contains t.lock chr
    | `HOLD -> String.contains t.hold chr
    | `FULL -> List.exists (mem chr t) [`USER; `LOCK; `HOLD]
    
  let add lvl1 lvl2 chr note =
    let usermode = (lvl1 = lvl2) in
    let o_user, o_lock, o_hold = note.user, note.lock, note.hold in
    let extra = String.make 1 chr in
    if usermode then note.user <- StringSet.union o_user extra;
    let n_hold, n_lock = get_rule lvl1 lvl2 extra in
    note.lock <- n_lock;
    note.hold <- n_hold;
    { log_user = (if usermode then [lvl1, StringSet.diff extra o_user] else []);
      log_lock = [lvl1, StringSet.diff n_lock o_lock];
      log_hold = [lvl1, StringSet.diff n_hold o_hold] }
end



module Changelog = struct
  let add ch1 ch2 = {
    log_user = ch1.log_user @ ch2.log_user;
    log_lock = ch1.log_lock @ ch2.log_lock;
    log_hold = ch1.log_hold @ ch2.log_hold;
  }
end

let get t lvl ~r ~c = 
  let get typ =
    List.map (fun x -> 
      x, Note.layer (Table.level t x).(r).(c) typ
    ) (Level.other lvl) in
  { log_user = get `USER;
    log_lock = get `LOCK;
    log_hold = get `HOLD }

let add t lvl ~r ~c chr =
  let mat = Table.level t lvl in
  if Note.mem chr mat.(r).(c) `FULL then None else (
    let log1 = Note.add lvl lvl chr mat.(r).(c) in
    let other = Array.of_list (Level.other lvl) in
    (* TODO: check this! *)
    let log2 = Note.add lvl other.(0) chr (Table.level t other.(0)).(r).(c)
    and log3 = Note.add lvl other.(1) chr (Table.level t other.(1)).(r).(c) in
    Some Changelog.(add (add log1 log2) log3)
  )

(*


module XXX = struct
  let add_with chr = 
    let tmp = String.make 1 chr in
    if String.contains "AVIH" chr then tmp ^ "R" else tmp
  let del_with chr =
    if chr = 'R' then "AVIHR" else String.make 1 chr
end



module Mask = struct
  let symlist = function
    | `COLONIZATION -> "XNY"
    | `ARB_VESICLES -> "XNVA"
    | `ALL_FEATURES -> "XRHEIVA"
  let of_string lvl str =
    let all = symlist lvl in
    let rec loop res = function
      | 0 -> res
      | i -> let elt = 1 lsl (String.index all str.[i - 1]) in
        loop (res lor elt) (i - 1)
    in loop 0 (String.length str)
  let of_char lvl chr = of_string lvl (String.make 1 chr)
  let to_string t lvl ~r ~c =
    let rec loop str = function
      | 0 -> str
      | i -> let j = i - 1 in
        

end



let set t lvl ~r ~c chr =
  let mat = Table.select t lvl in
  let old = mat.(r).(c).mask in
  let now = match lvl with
    | `COLONIZATION -> old lor (Mask.of_char lvl chr)
    | `ARB_VESICLES -> old lor (Mask.of_char lvl chr)
    | `ALL_FEATURES -> old lor (Mask.of_string lvl (Symbs.add_with chr))
  in mat.(r).(c).mask <- now;
  now = old

let unset t lvl ~r ~c chr =
  let mat = Table.select t lvl in
  let old = mat.(r).(c).mask in
  let now = match lvl with
    | `COLONIZATION -> old lxor (Mask.of_char lvl chr)
    | `ARB_VESICLES -> old lxor (Mask.of_char lvl chr)
    | `ALL_FEATURES -> old lxor (Mask.of_string lvl (Symbs.del_with chr))
  in mat.(r).(c).mask <- now;
  now = old

let add tbl lvl ~r ~c chr =
  let mat = Table.select tbl lvl in
  let edit = match Lock.get mat ~r ~c with
    | Some (x, _) when String.contains x chr -> false (* already exists. *)
    | Some (_, y) when String.contains y chr -> false (* incompatible.   *)
    | _ -> set t lvl ~r ~c chr
  in if edit then propagate ... (* TODO *)












(* All output values are sorted alphabetically. *)
module Rules = struct
  module Forbids = struct
    (* mutually exclusive. *)
    let colonization = function
      | 'Y' -> "NX"
      | 'N' -> "XY"
      |  _  -> "NY"
    let arb_vesicles = function
      | 'N' -> "AVX"
      | 'X' -> "ANV"
      |  _  -> "NX"
    let all_features = function
      | 'X' -> "AEHIRV"
      |  _  -> "" 
  end
  let forbids = function
    | `COLONIZATION -> Forbids.colonization
    | `ARB_VESICLES -> Forbids.arb_vesicles
    | `ALL_FEATURES -> Forbids.all_features
  let requires = function
    | `COLONIZATION -> (fun _ -> "")
    | `ARB_VESICLES -> (fun _ -> "")
    | `ALL_FEATURES -> (fun c -> if String.contains "AHIV" c then "R" else "")
  (* tells which annotation must get removed together. *)
  let erases = function
    | `COLONIZATION -> (fun _ -> "")
    | `ARB_VESICLES -> (fun _ -> "")
    | `ALL_FEATURES -> (function "R" -> "AHIV" | _ -> "")
end





(* String/note conversion functions, useful to save the table in a format that
 * can be easily parsed and converted back to table upon reloading. We do not
 * use input_value/output_value or Marshal to ensure compatibility with newer
 * versions of the OCaml compilers. The Jane Street core API is not used to
 * avoid relying on unnecessary dependencies. *)
module Note = struct
  let to_string = function
    | Null   -> "Null"
    | Mask n -> sprintf "Mask %d" n 
    | Pred t -> List.map (sprintf "%F") t 
      |> String.concat ";"
      |> sprintf "Pred %s"
    | Lock s -> sprintf "Lock %s" s (* "%S" adds extra parsing to of_string. *)

  let of_string str =
    let convert x y =
      match x with
      | "Null" -> Null
      | "Mask" -> Mask (int_of_string y)
      | "Lock" -> Lock y
      | "Pred" -> Pred (String.split_on_char ';' y |> List.map float_of_string)
      | _      -> assert false (* does not happen. *)
    in sscanf str "%4s %[^\n]" convert
end


(* This module converts the fully-featured annotation style used by CastANet 
 * MycBrowser into binary lists (i.e containing 0/1) for the purpose to output
 * a TSV table that CastANet Python programs can use. *)
module Binary = struct
  (* Returns the index of the largest element of a given list. *)
  let max_list_index = function
    | [] -> raise Not_found
    | x :: rem ->
      let rec loop i m j = function
        | [] -> i
        | x :: rem -> (if x > m then loop j x else loop i m) (j + 1) rem
      in loop 0 x 1 rem
  (* Example: list_of_int 4 0b1100 returns [1; 1; 0; 0]. *)
  let list_of_int n x = List.init n (fun i -> (x lsr (n - i - 1)) land 1)

  (* Implementation follows the order [Y; N; X]. *)
  let colonization = function
    | Null when !auto_background -> Some [0; 0; 1]
    | Mask n -> Some (list_of_int 3 n)
    | Pred t -> let r = Array.make 3 0 in
      r.(max_list_index t) <- 1; Some (Array.to_list r)
    | _ -> None

  (* Implementation follows the order [A; V; N; X]. *)
  let arb_vesicles = function
    | Null when !auto_background -> Some [0; 0; 0; 1]
    | Mask n -> Some (list_of_int 4 n)
    | Pred t -> let r = Array.make 4 0 in
      r.(max_list_index t) <- 1; Some (Array.to_list r)
    | _ -> None

  (* Implementation follows the order [A; V; I; E; H; R; X]. *)
  (* FIXME: what is the best way of converting probs to ints here? *)
  let all_features = function
    | Null when !auto_background -> Some [0; 0; 0; 0; 0; 0; 1]
    | Mask n -> Some (list_of_int 7 n)
    | Pred t -> let r = Array.make 7 0 in
      r.(max_list_index t) <- 1; Some (Array.to_list r)
    | _ -> None

  let of_note = function
    | `COLONIZATION -> colonization
    | `ARB_VESICLES -> arb_vesicles
    | `ALL_FEATURES -> all_features

  (* Conversion to note is independent of annotation type. *)
  let to_note t =
    let open List in
    if for_all ((=) "0") t then Null else
    if for_all (fun s -> s = "0" || s = "1") t then
      Mask (fold_left (fun n s -> (n lsl 1) lor (int_of_string s)) 0 t)
    else Pred (map float_of_string t)
end


module Table = struct
  let select = function
    | `COLONIZATION -> (fun t -> t.colonization)
    | `ARB_VESICLES -> (fun t -> t.arb_vesicles)
    | `ALL_FEATURES -> (fun t -> t.all_features)

  let string_of_matrix t =
    Matrix.map Note.to_string t
    |> Array.map (fun t -> Array.to_list t |> String.concat '\t')
    |> Array.to_list
    |> String.concat '\n'

  let matrix_of_string s =
    String.split_on_char '\n' s
    |> List.map (String.split_on_char '\t' |> Array.of_list)
    |> Array.of_list
    |> Matrix.map Note.of_string

  (* Converts tables to string and determine checksums. *)
  let to_string t =
    let x = string_of_matrix t.colonization
    and y = string_of_matrix t.arb_vesicles
    and z = string_of_matrix t.all_features in
    Digest.((x, string x), (y, string y), (z, string z))

  let of_string x y z = {
    colonization = matrix_of_string x,
    arb_vesicles = matrix_of_string y,
    all_features = matrix_of_string z }

  let header ann = code_list ann
    |> List.map (String.make 1)
    |> String.concat "\t"
    |> sprintf "row\tcol\t%s" 

  (* Returns a simplified version of the table that can be manipulated
   * by the Python scripts. Notes are transformed in 0/1 sequences (see Binary)
   * and the first two columns contain row and column index. *)
  let python_of_matrix ann tbl =
    let mat = select ann tbl in
    let hdr = header ann in
    let dat = Matrix.fold (fun r c res note ->
      match Binary.of_note ann note with
      | None -> res (* no conversion available, skipping. *)
      | Some t -> List.map string_of_int t
        |> String.concat "\t"
        |> sprintf "%d\t%d\t%s" r c 
      in elt :: res
    ) [] tbl in
    if dat = [] then None 
    else Some (String.concat "\n" (hdr :: List.rev dat))

  let may f = function None -> None | Some x -> Some (x, f x)

  (* Simplifies tables for Python scripts and determine checksums. *)
  let to_python_string t =
    let x = python_of_matrix `COLONIZATION t.colonization
    and y = python_of_matrix `ARB_VESICLES t.arb_vesicles
    and z = python_of_matrix `ALL_FEATURES t.all_features in
    Digest.(may string x, may string y, may string z)
end


let export t zip =
  let och = Zip.open_out zip in
  (* fully-featured matrices. *)
  let (x, dx), (y, dy), (z, dz) = Table.to_string t in
  Zip.add_entry x och "colonization.mldata" ~comment:dx;
  Zip.add_entry y och "arb_vesicles.mldata" ~comment:dy;
  Zip.add_entry z och "all_features.mldata" ~comment:dz;
  (* python-compatible tables (when available). *)
  let px, py, pz = Table.to_python_string t in
  let may_save tsv = function
    | None -> ()
    | Some (p, dp) -> Zip.add_entry p och tsv ~comment:dp in
  may_save "colonization.tsv" px;
  may_save "arb_vesicles.tsv" py;
  may_save "all_features.tsv" pz;
  Zip.close_out och


let import src =
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
    Some (Table.of_string xd yd zd)
  with Assert_failure _ | Zip.Error _ | Sys_error _ -> None


module Secure = struct
  let col2arb = function
    | 'Y' -> Lock "-NX" 
    | 'N' -> Lock "N-AVX" 
    |  _  -> Lock "X-ANV"
  let col2all = function
    | 'Y' -> Lock "R-X"
    | 'N' -> Lock "R-AHIVX"
    |  _  -> Lock "-AEHIRV"

  
end


module Edit = struct
  module Set = struct
    let colonization t ~r ~c chr =
      (* Bit order is 0bYNX (see module Binary above). Here values are mutually
       * exclusive so we can confidently erase any previous annotation. *)
      t.colonization.(r).(c) <- Mask (1 lsl (String.index "XNY" chr));
      t.arb_vesicles.(r).(c) <- Secure.col2arb chr;
      t.all_features.(r).(c) <- Secure.col2all chr
    
    
    
    let arb_vesicles t ~r ~c chr = (* ... *)
    let all_features t ~r ~c chr = (* ... *)
  end
  module Add = struct
  (* ... *)
  end
end


let set t = function
  | `COLONIZATION -> Edit.Set.colonization t
  | `ARB_VESICLES -> Edit.Set.arb_vesicles t
  | `ALL_FEATURES -> Edit.Set.all_features t










module Add = struct
  let set_one c1 c2 x = if c1 = c2 then 1.0 else x

  let colonization force t r c chr =
    
    let mask = Mask (1 lsl (String.index "XNY" chr)) in
    let ann = match t.colonization.(r).(c) with
      | Pred t -> Pred (List.map2 (set_one chr) Symbs.colonization t)
      | Lock s as Lock when String.contains s chr -> Lock (* forbidden! *)
      | _ -> mask
    in t.colonization.(r).(c) <- ann;
    (* Propagate changes to the other layers. *)
    propagate_arb_vesicles t r c chr;
    propagate_all_features t r c chr
    
  let arb_vesicles t r c chr = (* ... *)
  
  let all_features t r c chr = (* ... *)
  
end


(* Sets annotation. *)
let add t r c = function
  | `COLONIZATION -> Add.colonization force t r c
  | `ARB_VESICLES -> Add.arb_vesicles force t r c
  | `ALL_FEATURES -> Add.all_features force t r c
    





let ann_type = ref `BINARY
let annotation_type () = !ann_type
let is_gradient () = !ann_type = `GRADIENT

let generator f d (A t) chr =
  match List.assoc_opt chr index_list with
  | None -> CLog.warning "Unknown annotation %C" chr; d
  | Some i -> f t i

let add = generator (fun t i -> Array.set t i 1.0) ()
let mem = generator (fun t i -> Array.get t i > 0.0) false
let rem = generator (fun t i -> Array.set t i 0.0) ()
let get = generator Array.get 0.0

let get_group ?(palette = `VIRIDIS) (A t) chr =
  match List.assoc_opt chr index_list with
  | None -> assert false
  | Some i -> let size = CPalette.max_group palette in
    let x = t.(i) and r = 1.0 /. (float size) in
    let res = x /. r in
    let tmp = truncate res in
    if x -. r *. (float tmp) > 0.0 then tmp + 1 else tmp

let get_active (A t) =
  List.filter (fun x -> t.(snd x) > 0.0) index_list
  |> List.split
  |> fst
  |> List.map (String.make 1)
  |> String.concat ""

module Export = struct
  let empty () =
    let f, ext = match !ann_type with
      | `BINARY -> (fun _ -> "0"), ["1"]
      | `GRADIENT -> (fun _ -> "0.0"), ["1.0"]
    in List.map f code_list @ ext |> String.concat "\t"
  let as_int x = sprintf "%d" (truncate x)
  let as_float = sprintf "%.2f"
  let save f t = Array.map f t
    |> Array.to_list
    |> String.concat "\t"
  let to_string ((A t) as ann) =
    assert (exists ann);
    match !ann_type with
    | `BINARY -> save as_int t ^ "\t0"
    | `GRADIENT -> save as_float t ^ "\t0.0"
end
 
let export ~path mat =
  let och = open_out_bin path in
  List.map (String.make 1) code_list @ ["B"]
    |> String.concat "\t"
    |> fprintf och "row\tcol\t%s\n";
  CExt.Matrix.iteri (fun r c a ->
    let str = Export.(if is_empty a then empty () else to_string a) in
    fprintf och "%d\t%d\t%s\n" r c str
  ) mat;
  close_out och


module Import = struct
  (* Coordinate maps. *)
  module XY = struct
    type t = (int * int)
    let compare (a, b) (c, d) = 
      let cmp = compare a c in
      if cmp = 0 then compare b d else cmp
  end
  module XYMap = Map.Make(XY)

  (* Validate column headers. *)
  let validate_column_header s =
    try
      assert (String.length s = 1);
      let chr = s.[0] in 
      assert (chr = 'B' || String.contains codes chr);
      chr
    with Assert_failure _ ->
      CLog.error "Invalid column header '%s'" s

  (* Dissociate header from contents. *)
  let split_header = function
    | [] -> CLog.error "Empty TSV table"
    | header :: contents -> match CExt.Split.tabs header with
      | "row" :: "col" :: rem -> List.map validate_column_header rem, contents
      | _ -> CLog.error "Invalid TSV header"
  
  let parse_content_line str =
    sscanf str "%d\t%d\t%[^\n]"
      (fun x y dat -> (x, y), CExt.Split.tabs dat)

  let parse_contents t = 
    let rec loop map = function
      | [] -> map
      | (key, dat) :: rem -> loop (XYMap.add key dat map) rem 
    in loop XYMap.empty (List.rev_map parse_content_line t)
    
  let minmax tsv xy =
    match XYMap.(min_binding_opt xy, max_binding_opt xy) with
    | Some ((0, 0), _), Some ((r, c), _) -> r + 1, c + 1
    | _ -> CLog.error "Corrupted TSV file \"%s\"" tsv
    
  let annotation_type map =
    try
      XYMap.iter (fun _ dat ->
        let binary = List.for_all (fun s ->
          let x = float_of_string s in x = 0. || x = 1.
        ) dat in
        if not binary then raise Exit
      ) map;
      `BINARY
    with Exit -> `GRADIENT
   
  let create_float_array_annot hdr dat =
    let t = Array.copy empty_table in
    List.iter2 (fun chr dat ->
      if chr <> 'B' then
        sscanf dat "%f" (fun x -> t.(List.assoc chr index_list) <- x)
    ) hdr dat;
    A t
end


let import ~path:tsv =
  let header, contents = CExt.File.read tsv
    |> CExt.Split.lines
    |> Import.split_header in
  let xy_map = Import.parse_contents contents in
  let rs, cs = Import.minmax tsv xy_map in
  let typ = Import.annotation_type xy_map in
  ann_type := typ;
  Array.init rs (fun r ->
    Array.init cs (fun c ->
      match Import.XYMap.find_opt (r, c) xy_map with
      | Some dat when List.(length header = length dat) -> 
        Import.create_float_array_annot header dat
      | _ -> CLog.warning 
        "Missing or corrupted (%d, %d) line in TSV file \"%s\"" r c tsv;
        empty ()
  ))
*)
