(* CastANet - cPTable.ml *)

open CExt



class type prediction_table = object

    method level : CLevel.t
    
    method header : char list
    
    method get : r:int -> c:int -> float list

    method iter : (r:int -> c:int -> float list -> unit) -> unit

    method rows : int
    
    method columns : int

    method to_string : string

end



module Aux = struct

    open Scanf
    open Printf
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
        let matrix = Ext_Matrix.make (nrows assoc) (ncols assoc) [] in
        (* Populate the matrix with predictions. *)
        List.iter (fun ((r, c), t) -> Ext_Matrix.set matrix r c t) assoc;
        matrix

    (* First line contains header, other lines contain data. *)
    let read_table str =
        match index_opt str '\n' with
        | None -> invalid_arg "(CastANet.CPyTable) Empty table"
        | Some i -> let len = length str in
            header (sub str 0 i),
            contents (sub str (i + 1) (len - i - 1))

end



class prediction_table ~header ~contents = object (self)

    val header = header
    val matrix = contents

    method level = CLevel.of_header header
    method header = header

    method get ~r ~c = 
        if r >= 0 && r < self#rows 
        && c >= 0 && c < self#columns then matrix.(r).(c)
        else invalid_arg "(CPyTable.prediction_table#get) Out of range"  
    
    method iter f = Ext_Matrix.iteri f matrix

    method rows = Array.length matrix

    method columns = if self#rows = 0 then 0 else Array.length matrix.(0)

    method to_string =
        let header_str = List.map (String.make 1) header
            |> String.concat "\t"
            |> Printf.sprintf "row\tcol\t%s"
        and contents_str = 
            Ext_Matrix.to_string_rc
              ~cast:(fun ~r ~c t ->
                List.map Float.to_string t
                |> String.concat "\t"
                |> Printf.sprintf "%d\t%d\t%s" r c
              ) matrix
        in Printf.sprintf "%s\n%s" header_str contents_str

end



let create ~data = 
    let header, contents = Aux.read_table data in
    new prediction_table ~header ~contents


