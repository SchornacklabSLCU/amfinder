(* CastANet browser - imgDataset.ml *)

open Morelib



module Annotation = struct
    let of_string data =
        String.split_on_char '\n' data
        |> List.rev_map (String.split_on_char '\t')
        |> List.rev_map CMask.of_string
        |> Array.of_list
        |> Array.map Array.of_list

    let to_string data =
        Ext_Matrix.map (fun mask -> mask#to_string) data
        |> Array.map Array.to_list
        |> Array.map (String.concat "\t")
        |> Array.to_list
        |> String.concat "\n"
end



module Prediction = struct
    let line_to_assoc r c t =
        String.split_on_char '\t' t
        |> List.map Float.of_string
        |> (fun t -> (r, c), t

    let of_string data =
        let raw = List.map 
            (fun s -> 
                Scanf.sscanf s "%d\t%d\t%[^\n]" line_to_assoc
            ) (String.split_on_char '\n' data) in
        let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 raw + 1
        and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 raw + 1 in
        let table = Ext_Matrix.init nr nc (fun _ _ -> []) in  
        List.iter (fun ((r, c), t) -> table.(r).(c) <- t) raw;
        table

    let to_string data =
        let buf = Buffer.create 100 in
        (* Writes contents. *)
        Ext_Matrix.iteri (fun ~r ~c t ->
            List.map Float.to_string t
            |> String.concat "\t"
            |> bprintf buf "%d\t%d\t%s\n" r c
        ) data;
        Buffer.contents buf
end



class ['a] table = object
    method get : r:int -> c:int -> 'a
    method set : r:int -> c:int -> 'a -> unit
    method iter : (r:int -> c:int -> 'a -> unit) -> unit
    method to_string : string

end



class table matrix to_string = object
    method get ~r ~c = matrix.(r).(c)
    method set ~r ~c x = matrix.(r).(c) <- x
    method iter f = Array.(iteri (fun r -> iteri (fun c -> f ~r ~c)))
    method to_string = to_string matrix
end



class type ['a] t = object
    method get : CLevel.t -> r:int -> c:int -> 'a
    method set : CLevel.t -> r:int -> c:int -> 'a -> unit
    method iter : CLevel.t -> (r:int -> c:int -> 'a -> unit) -> unit
end



class ['a] dataset (assoc : (CLevel.t * 'a table) list) = object
    method get level = (List.assoc level assoc)#get
    method set level = (List.assoc level assoc)#set
    method iter level = (List.assoc level assoc)#iter
end



module Filter = struct
    let filter dir = List.filter (fun e -> Filename.dirname e.Zip.name = dir)
    let annotations = filter "annotations"
    let predictions = filter "predictions"
end



let empty_tables source =
    let r = source#rows and c = source#columns in
    List.iter (fun level ->
        level, Ext_Matrix.init ~r ~c (fun ~r:_ ~c:_ -> CMask.make ())
    ) CLevel.all_flags



let create source zip =
    let ich = Zip.open_in zip in
    let entries = Zip.entries ich in
    (* Loads annotations. *)
    let annotations = 
        List.map (fun entry ->
            let table = Zip.read_entry ich entry
                |> Annotation.of_string
                |> (fun t -> new table t Annotation.to_string)
            and level = CLevel.of_string (Filename.extension entry.name) in
            level, table
        ) (Filter.annotations entries)
    (* Loads predictions. *)
    and predictions =
        List.map (fun entry ->
            let table = Zip.read_entry ich entry
                |> Prediction.of_string
                |> (fun t -> new table t Prediction.to_string)
            and level = CLevel.of_string (Filename.extension entry.name) in
            level, table
        ) (Filter.predictions entries)
    in
    Zip.close_in ich;
    let annotations =
        if annotations = [] then empty_tables source 
        else annotations
    in (dataset annotations, dataset predictions)

