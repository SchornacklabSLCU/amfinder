(* CastANet browser - imgPredictions.ml *)

open Printf
open Morelib


module Aux = struct
    let line_to_assoc r c t =
        String.split_on_char '\t' t
        |> List.map Float.of_string
        |> (fun t -> (r, c), t)

    let of_string data =
        let raw = List.map 
            (fun s ->
                Scanf.sscanf s "%d\t%d\t%[^\n]" line_to_assoc
            ) (List.tl (String.split_on_char '\n' (String.trim data))) in
        let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 raw + 1
        and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 raw + 1 in
        let table = Matrix.init nr nc (fun ~r:_ ~c:_ -> []) in  
        List.iter (fun ((r, c), t) -> table.(r).(c) <- t) raw;
        table

    let to_string level table =
        let buf = Buffer.create 100 in
        (* TODO: improve this! *)
        let header = AmfLevel.to_header level
            |> List.map (String.make 1)
            |> String.concat "\t" in
        bprintf buf "row\tcol\t%s\n" header;
        Matrix.iteri (fun ~r ~c t ->
            List.map Float.to_string t
            |> String.concat "\t"
            |> bprintf buf "%d\t%d\t%s\n" r c
        ) table;
        Buffer.contents buf

    let mean t = List.(fold_left (+.) 0.0 t /. (float (length t)))

    let stdev t = 
        let m = mean t in
        let s = List.fold_left (fun r x -> r +. (x -. m) *. (x -. m)) 0.0 t in
        sqrt (s /. (float (List.length t)))
    
end


class predictions input = object (self)

    val mutable curr : string option = None
    val mutable sort : (int * int) array = [||]
    val mutable spos = 0

    method private sort_by_uncertainty id =
        (* Sort valyes by their standard deviation. *)
        let coords_sorted_by_sd = List.assoc id input
            |> snd
            |> Matrix.fold (fun ~r ~c res t -> ((r, c), Aux.stdev t) :: res) []
            |> List.sort (fun (_, x) (_, y) -> compare x y)
            |> List.map fst
            |> Array.of_list in
        sort <- coords_sorted_by_sd;
        spos <- 0

    method next_uncertain =
        if self#active then (
            spos <- spos + 1;
            try Some (Array.get sort spos) with _ -> None
        ) else None

    method current = curr

    method set_current = function
        | None -> curr <- None; sort <- [||]
        | Some id as some -> curr <- some; self#sort_by_uncertainty id

    method active =
        match curr with
        | None -> false
        | Some str -> fst (List.assoc str input) = AmfUI.Levels.current ()

    method ids level = 
        List.filter (fun (_, (x, _)) -> x = level) input
        |> List.split
        |> fst

    method count =
        match self#current with
        | None -> 0
        | Some id -> let mat = snd (List.assoc id input) in
            let r, c = Matrix.dim mat in r * c

    method dump och =
        List.iter (fun (id, (level, matrix)) ->
            Zip.add_entry
                ~comment:(AmfLevel.to_string level)
                (Aux.to_string level matrix) och 
                (sprintf "predictions/%s.tsv" id)
        ) input

    method private current_data = Option.map (fun x -> List.assoc x input) curr
    method private current_table = Option.map (fun (_, y) -> y) self#current_data
    method private current_level = Option.map (fun (x, _) -> x) self#current_data

    method get ~r ~c = 
        match self#current_table with
        | None -> None
        | Some t -> Matrix.get_opt t ~r ~c

    method exists ~r ~c = (self#get ~r ~c) <> None

    method private max level preds =
        List.fold_left2 (fun ((_, x) as z) y chr ->
            if y > x then (chr, y) else z
        ) ('0', 0.0) preds (AmfLevel.to_header level)

    method max_layer ~r ~c =
        match self#current_data with
        | None -> None
        | Some (level, table) -> let opt = Matrix.get_opt table ~r ~c in
            Option.map (self#max level) opt

    method iter (typ : [ `ALL of (r:int -> c:int -> float list -> unit)
        | `MAX of (r:int -> c:int -> char * float -> unit) ]) =
        Option.iter (fun (level, table) ->
            match typ with
            | `ALL f -> Matrix.iteri f table
            | `MAX f -> Matrix.iteri f (Matrix.map (self#max level) table)
        ) self#current_data

    method iter_layer chr f =
        match self#current_level with
        | None -> ()
        | Some level -> let header = AmfLevel.to_header level in
            let f = (fun ~r ~c t ->
                let elt, dat = 
                    List.fold_left2 (fun ((_, x) as o) chr y ->
                        if y > x then (chr, y) else o
                    ) ('0', 0.0) header t in
                if elt = chr then f ~r ~c dat)
            in self#iter (`ALL f)

    method statistics =
        match self#current_level with
        | None -> []
        | Some level -> let header = AmfLevel.to_header level in
            let counters = List.map (fun c -> c, ref 0) header in
            let f = (fun ~r ~c t ->
                let chr, _ = 
                    List.fold_left2 (fun ((_, x) as o) chr y ->
                        if y > x then (chr, y) else o
                    ) ('0', 0.0) header t
                in incr (List.assoc chr counters))
            in self#iter (`ALL f);
            List.map (fun (c, r) -> c, !r) counters

    method to_string () = 
        match self#current_data with
        | None -> "" (* TODO: Find a better solution to this! *)
        | Some (level, table) -> Aux.to_string level table

end


let filter entries =
    List.filter (fun {Zip.filename; _} ->
        Filename.dirname filename = "predictions"
    ) entries


let create ?zip source =
    match zip with
    | None -> new predictions []
    | Some ich -> let entries = Zip.entries ich in
        let assoc =
            List.map (fun ({Zip.filename; comment; _} as entry) ->
                let level = AmfLevel.of_string comment
                and matrix = Aux.of_string (Zip.read_entry ich entry)
                and id = Filename.(basename (chop_extension filename)) in
                id, (level, matrix)
            ) (filter entries)
        in new predictions assoc

