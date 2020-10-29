(** amf - imgDraw.ml *)

class draw 
  (tiles : ImgTypes.tile_matrix)
  (brush : ImgTypes.brush)
  (cursor : ImgTypes.cursor)
  (annot : ImgTypes.annotations)
  (preds : ImgTypes.predictions) 

= object (self)

    method tile ?(sync = true) ~r ~c () =
        match tiles#get ~r ~c with
        | None -> AmfLog.error ~code:Err.out_of_bounds "ImgDraw.draw#tile: \
            Index out of bounds (r = %d, c = %d)" r c
        | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf

    method cursor ?(sync = true) ~r ~c () =
        brush#cursor ~sync ~r ~c ();
        if preds#active then (
            let level = annot#current_level in
            let mask = annot#get ~level ~r ~c () in
            if mask#is_empty then (
                match preds#max_layer ~r ~c with
                | None -> brush#hide_probability ~sync:true ()
                | Some (chr, flo) -> let cur = annot#current_layer in
                    if cur = chr then brush#show_probability ~sync:true flo
                    else brush#hide_probability ~sync:true ()
            )
        )

    method pointer ?(sync = true) ~r ~c () =
        brush#pointer ~sync ~r ~c ()    

    method private annotation ?sync ~r ~c mask =
        let level = annot#current_level in
        match annot#current_layer with
        | '*' -> brush#annotation ?sync ~r ~c level '*'
        | chr -> match mask#mem chr with
            | true  -> brush#annotation ?sync ~r ~c level chr
            | false -> () (* no annotation in this layer. *)

    method private prediction ?sync ~r ~c () =
        if preds#active then
            match preds#max_layer ~r ~c with
            | None -> () (* is that possible? *)
            | Some (chr, flo) -> let level = annot#current_level in
                match annot#current_layer with
                | '*' -> Option.iter (brush#pie_chart ?sync ~r ~c) (preds#get ~r ~c)
                | cur when chr = cur -> brush#prediction ~sync:false ~r ~c chr flo;
                | _ -> () (* Not to be displayed. *)

    method overlay ?(sync = true) ~r ~c () =
        let level = annot#current_level in
        let mask = annot#get ~level ~r ~c () in
        (* Gives priority to annot over preds. *)
        if mask#is_empty then self#prediction ~sync ~r ~c ()
        else self#annotation ~sync ~r ~c mask

end


let create a b c d e = new draw a b c d e
