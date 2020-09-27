(* CastANet - cTable.ml *)

open CExt
open Printf



type 'a source = [
    | `DATA of 'a array array
    | `INIT of int * int * (int -> int -> 'a)
]


class type ['a] table = object

    method rows : int
    
    method columns : int

    method level : CLevel.t
    
    method header : char list

    method get : r:int -> c:int -> 'a
    
    method set : r:int -> c:int -> 'a -> unit

    method iter : (r:int -> c:int -> 'a -> unit) -> unit

end



class ['a] table (source : 'a source) level = object (self)

    val data = match source with
        | `DATA data -> data (* must be well formed. *)
        | `INIT (nr, nc, f) -> Array.(init nr (fun r -> init nc (f r)))

    method rows = Array.length data   
    method columns = if self#rows = 0 then 0 else Array.length data.(0)

    method level = level
    method header = CLevel.to_header level

    method get ~r ~c =
        if r >= 0 && r < self#rows
        && c >= 0 && c < self#columns then data.(r).(c)
        else invalid_arg "CTable.table#get: Out of range"

    method set ~r ~c x =
        if r >= 0 && r < self#rows
        && c >= 0 && c < self#columns then data.(r).(c) <- x
        else invalid_arg "CTable.table#set: Out of range"

    method iter f = Array.(iteri (fun r -> iteri (fun c -> f ~r ~c))) data

end



class type prediction_table = object

    inherit [float list] table
    
    method basename : string
    
    method set_basename : string -> unit
    
    method filename : string
    
    method to_string : string

end



class prediction_table source level name = object (self)

    inherit table source level

    val mutable base = name 

    method basename = base
    method set_basename x = base <- x

    method filename = Printf.sprintf "predictions/%s.%s" self#basename 
        (CLevel.to_string self#level)

    method to_string =
        let buf = Buffer.create 100 in
        (* Writes header. *)
        List.map (String.make 1) self#header
        |> String.concat "\t"
        |> Printf.bprintf buf "row\tcol\t%s\n";
        (* Writes contents. *)
        Ext_Matrix.iteri (fun ~r ~c t ->
            List.map Float.to_string t
            |> String.concat "\t"
            |> Printf.bprintf buf "%d\t%d\t%s\n" r c
        ) data;
        Buffer.contents buf

end



class type annotation_table = object

    inherit [CMask.layered_mask] table

    method filename : string
    
    method stats : (char * int) list
    
    method to_string : string

end



class annotation_table source level = object (self)

    inherit table source level

    method filename = sprintf "annotations/table.%s" (CLevel.to_string level)

    method stats =
        let counters = List.map (fun x -> x, ref 0) self#header in
        Ext_Matrix.iter (fun mask ->
            String.iter (fun chr ->
                incr (List.assoc chr counters)
            ) mask#all (* all active annotations. *)
        ) matrix;
        List.map (fun (x, r) -> x, !r) counters

    method to_string =
        Ext_Matrix.map (fun mask -> mask#to_string) data
        |> Array.map Array.to_list
        |> Array.map (String.concat "\t")
        |> Array.to_list
        |> String.concat "\n"

end



let create ~rows:nr ~columns:nc =
    let source = `INIT (nr, nc, (fun _ _ -> CMask.make ())) in
    List.map (fun level ->
        new annotation_table source level
    ) CLevel.all_flags



module Load_aux = struct

    open Zip

    let filter dir = List.filter (fun e -> Filename.dirname e.name = dir)

    let annotations = filter "annotations"
    let predictions = filter "predictions"
    let activations = filter "activations"

    let string_to_annotation_table raw =
        String.split_on_char '\n' raw
        |> List.rev_map (String.split_on_char '\t')
        |> List.rev_map CMask.of_string
        |> Array.of_list
        |> Array.map Array.of_list

    let string_to_prediction_table raw =
        (* First line contains header, other lines contain data. *)
        let header, contents =
            match String.index_opt raw '\n' with
            | None -> invalid_arg "(CTable.load) Empty table"
            | Some i -> let len = String.length raw in
                String.sub raw 0 i, String.sub raw (i + 1) (len - i - 1)
        in
        (* Example of header format: "row\tcol\tN\tV\tX" *)
        let level =
            Scanf.sscanf header "row\tcol\t%[^\n]" (String.split_on_char '\t')
            |> List.map (fun s -> if length s = 0 then '?' else s.[0])
            |> CLevel.of_header
        in
        (* Creates an intermediate table containing predictions. *)
        let tmp = 
            List.rev_map (fun line ->
                Scanf.sscanf line "%d\t%d\t%[^\n]"
                    (fun r c probs ->
                        let t = String.split_on_char '\t' probs
                            |> List.map Float.of_string
                        in ((r, c), t))
            ) (String.split_on_char '\n' contents)
        in
        (* Retrieves matrix dimensions. *)
        let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 tmp + 1
        and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 tmp + 1 in
        (* Populates the output table. *)
        let table = Ext_Matrix.init nr nc (fun _ _ -> []) in  
        List.iter (fun ((r, c), t) -> table.(r).(c) <- t) tmp;
        table

end


let load zip =
    let ich = Zip.open_in zip in
    let entries = Zip.entries ich in
    (* Loads annotations. *)
    let annotations = 
        match Load_aux.annotations entries with
        | [] -> [] (* predictions only! *)
        | at -> List.map (fun entry ->
            let raw = Zip.read_entry ich entry in
            let level = CLevel.of_string (Filename.extension entry.name)
            and source = `DATA (Load_aux.string_to_annotation_table raw) in
            new annotation_table source level) at
    (* Loads predictions. *)
    and predictions = List.map
        (fun entry ->
            let raw = Zip.read_entry ich entry in
            let name = Filename.(basename (remove_extension entry.name))
            and level = CLevel.of_string (Filename.extension entry.name)
            and source = `DATA (Load_aux.string_to_prediction_table raw) in
            new prediction_table source level name
        ) (Load_aux.predictions entries);
    in
    Zip.close_in ich;
    annotations, predictions



let save ~zip annotations predictions =
    let och = Zip.open_out zip in
    (* Saves annotation tables. *)
    List.iter (fun a_table ->
        Zip.add_entry a_table#to_string och a_table#filename
    ) annotations;
    (* Saves prediction tables. *)
    List.iter (fun p_table ->
        Zip.add_entry p_table#to_string och p_table#filename
    ) predictions;
    Zip.close_out och

