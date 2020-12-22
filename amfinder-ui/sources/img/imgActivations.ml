(* AMFinder - img/imgActivations.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

open Printf
open Morelib

(* FIXME: The very same code is in ImgTileMatrix. *)
module Aux = struct
    let crop ~src_x ~src_y ~edge pix =
        let dest = GdkPixbuf.create ~width:edge ~height:edge () in
        GdkPixbuf.copy_area ~dest ~src_x ~src_y pix;
        dest

    let resize ?(interp = `NEAREST) edge pixbuf =
        let width = GdkPixbuf.get_width pixbuf
        and height = GdkPixbuf.get_height pixbuf in
        let scale_x = float edge /. (float width)
        and scale_y = float edge /. (float height) in
        let dest = GdkPixbuf.create ~width:edge ~height:edge () in
        GdkPixbuf.scale ~dest ~scale_x ~scale_y ~interp pixbuf;
        dest
end



class activations
    (source : ImgTypes.source) 
    (input : (string * (char * GdkPixbuf.pixbuf)) list) edge 

= object

    val hash =
        let hash = Hashtbl.create 11 in
        List.iter (fun (id, data) ->
            match Hashtbl.find_opt hash id with
            | None -> Hashtbl.add hash id [data]
            | Some old -> Hashtbl.replace hash id (data :: old)
        ) input;
        hash

    method active = AmfUI.Predictions.cams#get_active

    method get id chr ~r ~c =
        try
            let pixbuf = List.assoc chr (Hashtbl.find hash id) in
            let src_x = c * source#edge 
            and src_y = r * source#edge in
            Aux.crop ~src_x ~src_y ~edge:source#edge pixbuf
            |> Aux.resize edge
            |> Option.some
        with exn -> 
            AmfLog.warning "ImgTileMatrix.activations#get \
            %S %C ~r=%d ~c=%d triggered exception %S" id chr r c 
            (Printexc.to_string exn);
            None

    method dump och =
        List.iter (fun (id, (chr, pixbuf)) ->
            let buf = Buffer.create 100 in
            GdkPixbuf.save_to_buffer pixbuf ~typ:"jpeg" buf;
            Zip.add_entry
                ~comment:(String.make 1 chr)
                (Buffer.contents buf) och
                (sprintf "activations/%s.%c.jpg" id chr)
        ) input

end

let filter entries =
    List.filter (fun e -> 
        Filename.dirname e.Zip.filename = "activations"
    ) entries

let create ?zip source =
    match zip with
    | None -> new activations source [] 180
    | Some ich -> let entries = Zip.entries ich in
        let table = 
            List.map (fun ({Zip.filename; comment; _} as entry) ->
                let chr = Scanf.sscanf comment "%c" Char.uppercase_ascii
                and id = Filename.(basename (chop_extension (chop_extension filename))) in
                let tmp, och = Filename.open_temp_file
                    ~mode:[Open_binary] 
                    "castanet" ".jpg" in
                Zip.copy_entry_to_channel ich entry och;
                close_out och;
                AmfLog.info "Loading activation map %S" tmp;
                let pixbuf = GdkPixbuf.from_file tmp in
                Sys.remove tmp;
                id, (chr, pixbuf) 
            ) (filter entries)
        in new activations source table 180
