(* CastANet browser - imgAnnotations.ml *)

open Scanf
open Printf
open Morelib

module Aux = struct
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



class annotations (assoc : (CLevel.t * CMask.layered_mask Matrix.t) list) = 

object (self)

    method private level x = List.assoc x assoc
    method get x ~r ~c = Matrix.get_opt (self#level x) ~r ~c

    method iter x f = Matrix.iteri f (self#level x)

    method iter_layer x layer f =
        let has_layer = match layer with
            | '*' -> (fun mask -> String.length mask#all > 0)
            | chr -> (fun mask -> String.contains mask#all chr)
        in
        Matrix.iteri (fun ~r ~c mask ->
            if has_layer mask then f ~r ~c mask
        ) (self#level x)

    method statistics level =
        let counters = List.map (fun c -> c, ref 0) (CLevel.to_header level) in
        self#iter level (fun ~r ~c mask ->
            String.iter (fun chr -> incr (List.assoc chr counters)) mask#all
        );
        List.map (fun (c, r) -> c, !r) counters

    method to_string x = Aux.to_string (self#level x)

end


let filter entries = 
    List.filter (fun e -> 
        Filename.dirname e.Zip.filename = "annotations"
    ) entries


let empty_tables source =
    let r = source#rows and c = source#columns in
    List.map (fun level ->
        level, Matrix.init ~r ~c (fun ~r:_ ~c:_ -> CMask.make ())
    ) CLevel.all_flags


let create ?zip source =
    match zip with
    | None -> new annotations (empty_tables source)
    | Some ich -> let entries = Zip.entries ich in
        match filter entries with
        | [] -> new annotations (empty_tables source)
        | entries ->
            let tables = 
                List.map (fun ({Zip.filename; _} as entry) ->
                    let table = Aux.of_string (Zip.read_entry ich entry)
                    and level = CLevel.of_string (Filename.extension filename) in
                    level, table
                ) entries
            in new annotations tables
