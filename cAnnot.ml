(* CastANet - cAnnot.ml *)

open CExt
open Scanf
open Printf

let codes = "AVIEHRD"
let ncodes = String.length codes
let code_list = CExt.CString.fold_right List.cons codes []
let index_list = Array.(of_list code_list |> mapi (fun i c -> c, i) |> to_list)

type t = A of float array

let empty_table = Array.make ncodes 0.0

let empty () = A (Array.copy empty_table)

let is_empty (A t) = t = empty_table

let ann_type = ref `BINARY
let annotation_type () = !ann_type

let generator f d (A t) chr =
  match List.assoc_opt chr index_list with
  | None -> tagger_warning "Unknown annotation %C" chr; d
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
  let as_int x = sprintf "%d" (truncate x)
  let as_float = sprintf "%.2f"
  let save f t = Array.map f t
    |> Array.to_list
    |> String.concat "\t"
  let to_string (A t) =
    match !ann_type with
    | `BINARY -> save as_int t
    | `GRADIENT -> save as_float t
end
 
let export ~path mat =
  let och = open_out_bin path in
  List.map (String.make 1) code_list
    |> String.concat "\t"
    |> fprintf och "row\tcol\t%s\n";
  tagger_matrix_iteri (fun r c a ->
    fprintf och "%d\t%d\t%s\n" r c (Export.to_string a)
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
      assert (String.contains codes chr);
      chr
    with Assert_failure _ ->
      tagger_error "Invalid column header '%s'" s

  (* Dissociate header from contents. *)
  let split_header = function
    | [] -> tagger_error "Empty TSV table"
    | header :: contents -> match tagger_split_tabs header with
      | "row" :: "col" :: rem -> List.map validate_column_header rem, contents
      | _ -> tagger_error "Invalid TSV header"
  
  let parse_content_line str =
    sscanf str "%d\t%d\t%[^\n]"
      (fun x y dat -> (x, y), tagger_split_tabs dat)

  let parse_contents t = 
    let rec loop map = function
      | [] -> map
      | (key, dat) :: rem -> loop (XYMap.add key dat map) rem 
    in loop XYMap.empty (List.rev_map parse_content_line t)
    
  let minmax tsv xy =
    match XYMap.(min_binding_opt xy, max_binding_opt xy) with
    | Some ((0, 0), _), Some ((r, c), _) -> r + 1, c + 1
    | _ -> tagger_error "Corrupted TSV file \"%s\"" tsv
    
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
      sscanf dat "%f" (fun x -> t.(List.assoc chr index_list) <- x)
    ) hdr dat;
    A t  
end



let import ~path:tsv =
  let header, contents = tagger_read_file tsv
    |> tagger_split_lines
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
      | _ -> tagger_warning 
        "Missing or corrupted (%d, %d) line in TSV file \"%s\"" r c tsv;
        empty ()
  ))