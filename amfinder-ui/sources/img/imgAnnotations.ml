(* The Automated Mycorrhiza Finder version 1.0 - img/imgAnnotations.ml *)

open Scanf
open Printf
open Morelib

module Aux = struct
    let of_string data =
        String.split_on_char '\n' data
        |> List.map (String.split_on_char '\t')
        |> Array.of_list
        |> Array.map Array.of_list

    let to_string level data =
        Matrix.map (fun (annot : AmfAnnot.annot) -> 
            annot#get ~level ()
            |> CSet.to_seq
            |> String.of_seq    
        ) data
        |> Array.map Array.to_list
        |> Array.map (String.concat "\t")
        |> Array.to_list
        |> String.concat "\n"
                
    let to_python level (data : AmfAnnot.annot Matrix.t) =
        let rows = Array.length data
        and columns = Array.length data.(0) in
        let buf = Buffer.create 100 in
        for i = 0 to rows * columns - 1 do
            let r = i / columns and c = i mod columns in
            let mask = data.(r).(c) in
            if mask#has_annot ~level () then
                bprintf buf "%d\t%d\t%s\n" r c
                (mask#hot ~level () 
                    |> List.map string_of_int
                    |> String.concat "\t")
        done;
        let res = Buffer.contents buf in
        if String.length res = 0 then None else
            let header = sprintf "row\tcol\t%s\n" (
                AmfLevel.to_header level 
                |> List.map (String.make 1) 
                |> String.concat "\t"
            ) in Some (String.trim (header ^ res))      
end


class annotations (source : ImgTypes.source) root_segm ir_struct =

    let table =
        match root_segm with
        | None -> let r = source#rows and c = source#columns in
            Matrix.init ~r ~c (fun ~r:_ ~c:_ -> AmfAnnot.create ())
        | Some root_segm -> let seg = Aux.of_string root_segm in
            match ir_struct with
            | None -> Matrix.map AmfAnnot.of_string seg
            | Some myc ->
                Matrix.map2 (fun rs is ->
                    AmfAnnot.of_string (rs ^ is)
                ) seg (Aux.of_string myc)
    in

object (self)

    method get ~r ~c () = Matrix.get table ~r ~c

    method has_annot ?level ~r ~c () = (self#get ~r ~c ())#has_annot ?level ()

    method iter f = Matrix.iteri f table

    method iter_layer layer f =
        let has_layer = match layer with
            | '*' -> (fun (mask : AmfAnnot.annot) -> CSet.cardinal (mask#get ()) > 0)
            | chr -> (fun (mask : AmfAnnot.annot) -> CSet.mem chr (mask#get ()))
        in
        Matrix.iteri (fun ~r ~c annot ->
            if has_layer annot then f ~r ~c annot
        ) table

    method statistics ?(level = AmfUI.Levels.current ()) () =
        let counters = AmfLevel.to_header level
            |> List.map (fun c -> c, ref 0) in
        self#iter (fun ~r:_ ~c:_ (mask : AmfAnnot.annot) ->
            CSet.iter (fun chr ->
                incr (List.assoc chr counters)
            ) (mask#get ~level ())
        );
        List.map (fun (c, r) -> c, !r) counters

    method dump och =
        List.iter (fun level ->
            let file = AmfLevel.to_string level
                |> sprintf "annotations/%s.caml" in
            Zip.add_entry (Aux.to_string level table) och file;
            (* Create Python table for use with Python amf scripts. *)
            match Aux.to_python level table with
            | None -> ()
            | Some data -> let lvl_string = AmfLevel.to_string level in
                Zip.add_entry data och (sprintf "%s.tsv" lvl_string)
        ) AmfLevel.[RootSegm; IRStruct]

end


let retrieve_annotations ich entries =
    let root_segm = ref None and ir_struct = ref None in
    List.iter (fun entry ->
        let path = entry.Zip.filename in
        if Filename.dirname path = "annotations" then
            match Filename.basename path with
            | "RootSegm.caml" -> root_segm := Some (Zip.read_entry ich entry)
            | "IRStruct.caml" -> ir_struct := Some (Zip.read_entry ich entry)
            | any -> AmfLog.error ~code:Err.Image.unknown_annotation_file
                "Unknown annotation file %S" any 
    ) entries;
    (!root_segm, !ir_struct)



let create ?zip source =
    match zip with
    | None -> new annotations source None None
    | Some ich -> let entries = Zip.entries ich in
        match retrieve_annotations ich entries with
        | None, _ -> new annotations source None None
        | root_segm, ir_struct -> new annotations source root_segm ir_struct