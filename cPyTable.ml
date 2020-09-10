(* CastANet - cPyTable.ml *)

open CExt
open Printf

type pytable = {
  py_label : string;                    (* Base name without extension.    *)
  py_level : CLevel.t;                  (* Annotation level (from header). *)
  py_header : char list;                (* Header character order.         *)
  py_matrix : float list Ext_Matrix.t;  (* Probabilities.                  *)
}

let label t = t.py_label
let level t = t.py_level
let header t = t.py_header
let matrix t = t.py_matrix

let ensure_consistency f = function
  | [] -> [] (* nothing to be checked here. *)
  | hdr :: rem as dat -> let n = f hdr in
    assert (List.for_all (fun x -> f x = n) rem);
    dat

let s2i = int_of_string

let load ~tsv =
  assert (Sys.file_exists tsv);
  let valid_input_list = Ext_File.read tsv
    |> String.split_on_char '\n'
    |> List.map (String.split_on_char '\t')
    |> ensure_consistency List.length in
  match valid_input_list with
  | [] -> CLog.error "Empty prediction table (CPyTable.load)"
  | hdr :: dat ->
    let py_header = match hdr with
      | _ :: _ :: z -> List.map (fun s -> s.[0]) z
      | _ -> assert false
    and probs = List.map (function
      | x :: y :: z -> (s2i x, s2i y), List.map Float.of_string z
      | _ -> assert false) dat
    and py_label = Filename.(basename tsv |> remove_extension) in
    let py_level = CLevel.of_list py_header in
    let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 probs + 1
    and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 probs + 1 in
    let py_matrix = Ext_Matrix.init nr nc (fun r c -> List.assoc (r, c) probs) in
    {py_label; py_level; py_header; py_matrix}


let to_string pytable =
  let mat = matrix pytable in
  let nr, nc = Ext_Matrix.dim mat in
  (* loop is tail-rec to ensure it does not fail on very large tables. Items
   * get inserted in reverse order so there is no need for List.rev. *)
  let rec loop res r c =
    if r > 0 then (
      if c > 0 then (
        let r' = r - 1 and c' = c - 1 in
        Ext_Matrix.get mat r' c'
        |> List.map Float.to_string
        |> String.concat "\t"
        |> sprintf "%d\t%d\t%s" r' c'
        |> (fun elt -> loop (elt :: res) r (c - 1)) 
      ) else loop res (r - 1) nc
    ) else res
  in
  header pytable
  |> List.map (String.make 1)
  |> String.concat "\t"
  |> sprintf "row\tcol\t%s"
  |> (fun hdr -> hdr :: loop [] nr nc)
  |> String.concat "\n"

