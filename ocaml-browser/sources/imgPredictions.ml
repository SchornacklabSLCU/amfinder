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

    let to_string data =
        let buf = Buffer.create 100 in
        (* TODO: improve this! *)
        let header = match List.length data.(0).(0) with
            | 3 -> "Y\tN\tX"
            | 4 -> "A\tV\tN\tX"
            | 7 -> "A\tV\tE\tI\tH\tR\tX"
            | _ -> invalid_arg "ImgPredictions.Aux.to_string: Unknown header" in
        bprintf buf "row\tcol\t%s\n" header;
        Matrix.iteri (fun ~r ~c t ->
            List.map Float.to_string t
            |> String.concat "\t"
            |> bprintf buf "%d\t%d\t%s\n" r c
        ) data;
        Buffer.contents buf
end


class predictions assoc_table = object

    val mutable curr : string option = 
        match assoc_table with
        | [] -> None (* TODO: Find a better solution to this! *)
        | (id, _) :: _ -> Some id

    method current = curr
    method set_current x = curr <- Some x

    method get ~r ~c =
        match curr with
        | None -> None
        | Some x -> Matrix.get_opt (List.assoc x assoc_table) ~r ~c

    method iter f =
        match curr with
        | None -> ()
        | Some x -> Matrix.iteri f (List.assoc x assoc_table)

    method to_string () = 
        match curr with
        | None -> "" (* TODO: Find a better solution to this! *)
        | Some x -> Aux.to_string (List.assoc x assoc_table)

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
            List.map (fun ({Zip.filename; _} as entry) ->
                let matrix = Aux.of_string (Zip.read_entry ich entry)
                and id = Filename.(basename (chop_extension filename)) in
                id, matrix
            ) (filter entries)
        in new predictions assoc

