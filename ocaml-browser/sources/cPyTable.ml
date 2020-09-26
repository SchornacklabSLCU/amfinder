(* CastANet - cPyTable.ml *)

open CExt
open Scanf
open Printf

type python_table = {
    pt_label : string;                    (* Base name without extension.    *)
    pt_level : CLevel.t;                  (* Annotation level (from header). *)
    pt_header : char list;                (* Header character order.         *)
    pt_matrix : float list Ext_Matrix.t;  (* Probabilities.                  *)
}

let label t = t.py_label
let level t = t.py_level
let header t = t.py_header
let matrix t = t.py_matrix



module OfString = struct

    open String

    (* Example of header format: "row\tcol\tN\tV\tX" *)
    let header str =
        sscanf str "row\tcol\t%[^\n]" (split_on_char '\t')
        |> List.map (fun s -> if length s = 0 then '?' else s.[0])
        |> List.map Char.uppercase_ascii

    let line str =
        let assoc r c dat =
            let raw = split_on_char '\t' dat in
            (r, c), List.map Float.of_string raw
        in sscanf str "%d\t%d\t%[^\n]" assoc

    let nrows t = List.fold_left (fun m ((r, _), _) -> max m r) 0 t + 1
    let ncols t = List.fold_left (fun m ((_, c), _) -> max m c) 0 t + 1

    let contents str =
        (* Make an association list of coordinates (r, c) and predictions. *)
        let assoc = List.map line (split_on_char '\n' str) in
        (* Creates an empty matrix. *)
        let matrix = Ext_Matrix.make (nrows assoc) (ncols assoc) [||] in
        (* Populate the matrix with predictions. *)
        List.iter (fun ((r, c), t) -> Ext_Matrix.set matrix r c t) assoc;
        matrix

    (* First line contains header, other lines contain data. *)
    let table str =
        match index_opt str '\n' with
        | None -> invalid_arg "(CastANet.CPyTable) Empty table"
        | Some i -> let len = length str in
            header (sub str 0 i),
            contents (sub str (i + 1) (len - i - 1))

end



let from_string ~path str =
    (* Retrieve table header and contents. *)
    let pt_header, pt_matrix = OfString.table str in
    (* Retrieve the corresponding annotation level. *)
    let pt_level =
        match List.length pt_header with
        | 3 -> `COLONIZATION
        | 4 -> `ARB_VESICLES
        | 7 -> `ALL_FEATURES
        | _ -> invalid_arg "(CastANet.CPyTable) Wrong header size"
    in
    (* Create Python table label (to be displayed) from its path. *)
    let pt_label = Filename.(basename (remove_extension path)) in
    (* Creates the final Python table *)
    { pt_label; pt_level; pt_header; pt_matrix } 



module ToString = struct

    let header labels =
        List.map (String.make 1) labels
        |> String.concat "\t"
        |> sprintf "row\tcol\t%s"

    let data ~r ~c probs =
        List.map Float.to_string probs
            |> String.concat "\t"
            |> sprintf "%d\t%d\t%s" r c

end

let to_string {pt_header; pt_matrix; _} =
    sprintf "%s\n%s"
        (ToString.header pt_header)
        (Ext_Matrix.to_string_rc ~cast:ToString.data pt_matrix)
