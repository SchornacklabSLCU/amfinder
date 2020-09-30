(* CastANet browser - imgDataset.ml *)

open Printf
open Morelib



module Annotation = struct
    let of_string data =
        String.split_on_char '\n' data
        |> List.rev_map (String.split_on_char '\t')
        |> List.rev_map (List.map CMask.of_string)
        |> Array.of_list
        |> Array.map Array.of_list

    let to_string data =
        Matrix.map (fun mask -> mask#to_string) data
        |> Array.map Array.to_list
        |> Array.map (String.concat "\t")
        |> Array.to_list
        |> String.concat "\n"
end



module Prediction = struct
    let line_to_assoc r c t =
        String.split_on_char '\t' t
        |> List.map Float.of_string
        |> (fun t -> (r, c), t)

    let of_string data =
        let raw = List.map 
            (fun s -> 
                Scanf.sscanf s "%d\t%d\t%[^\n]" line_to_assoc
            ) (String.split_on_char '\n' data) in
        let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 raw + 1
        and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 raw + 1 in
        let table = Matrix.init nr nc (fun ~r:_ ~c:_ -> []) in  
        List.iter (fun ((r, c), t) -> table.(r).(c) <- t) raw;
        table

    let to_string data =
        let buf = Buffer.create 100 in
        (* Writes contents. *)
        Matrix.iteri (fun ~r ~c t ->
            List.map Float.to_string t
            |> String.concat "\t"
            |> bprintf buf "%d\t%d\t%s\n" r c
        ) data;
        Buffer.contents buf
end







class ['a] table (matrix : 'a array array) (to_string : 'a array array -> string) = 
object
    method get ~r ~c = try Some matrix.(r).(c) with _ -> None
    method set ~r ~c x = matrix.(r).(c) <- x
    method iter f = Array.(iteri (fun r -> iteri (fun c -> f ~r ~c))) matrix
    method to_string = to_string matrix
end



class ['a] dataset (assoc : (CLevel.t * 'a table) list) = object
    method get level = (List.assoc level assoc)#get
    method set level = (List.assoc level assoc)#set
    method iter level = (List.assoc level assoc)#iter
end



module Filter = struct
    open Zip
    let filter dir = List.filter (fun e -> Filename.dirname e.filename = dir)
    let annotations = filter "annotations"
    let predictions = filter "predictions"
end



let empty_tables source =
    let r = source#rows and c = source#columns in
    List.map (fun level ->
        let matrix = Matrix.init ~r ~c (fun ~r:_ ~c:_ -> CMask.make ()) in
        level, new table matrix Annotation.to_string
    ) CLevel.all_flags



let create source zip =
    let open Zip in
    if Sys.file_exists zip then begin
        let ich = open_in zip in
        let entries = entries ich in
        (* Loads annotations. *)
        let annotations = 
            List.map (fun entry ->
                let table = read_entry ich entry
                    |> Annotation.of_string
                    |> (fun t -> new table t Annotation.to_string)
                and level = CLevel.of_string (Filename.extension entry.filename) in
                level, table
            ) (Filter.annotations entries)
        (* Loads predictions. *)
        and predictions =
            List.map (fun entry ->
                let table = read_entry ich entry
                    |> Prediction.of_string
                    |> (fun t -> new table t Prediction.to_string)
                and level = CLevel.of_string (Filename.extension entry.filename) in
                level, table
            ) (Filter.predictions entries)
        in
        close_in ich;
        let annotations =
            if annotations = [] then new dataset (empty_tables source) 
            else new dataset annotations
        in (annotations, new dataset predictions)
    end else (new dataset (empty_tables source), new dataset [])
