(* CastANet Browser - imgSource.ml *)

open Scanf
open Printf

class source ?zip pixbuf =

    let edge =
        match zip with
        | None -> !AmfPar.edge
        | Some ich -> Zip.find_entry ich "settings.json"
            |> Zip.read_entry ich
            |> (fun s -> sscanf s "{\"tile_edge\": %d}" (fun n -> n)) in

object (self)

    val width = GdkPixbuf.get_width pixbuf

    val height = GdkPixbuf.get_height pixbuf

    method edge = edge

    method width = width

    method height = height

    method rows = height / edge

    method columns = width / edge

    method save_settings och =
        let data = sprintf "{\"tile_edge\": %d}" edge in
        Zip.add_entry data och "settings.json"

end


let create ?zip pixbuf = new source ?zip pixbuf
