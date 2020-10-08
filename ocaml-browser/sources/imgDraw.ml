(** amf - imgDraw.ml *)

class draw 
  (tiles : ImgTileMatrix.tile_matrix)
  (brush : ImgBrush.brush)
  (annot : ImgAnnotations.annotations)
  (preds : ImgPredictions.predictions) 

= object (self)

    method tile ?(sync = true) ~r ~c () =
        match tiles#get ~r ~c with
        | None -> CLog.error ~code:Err.out_of_bounds "ImgDraw.draw#tile: \
            Index out of bounds (r = %d, c = %d)" r c
        | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf

    method cursor ?(sync = true) ~r ~c () =
        self#tile ~sync:false ~r ~c ();
        brush#cursor ~sync ~r ~c ()

    method pointer ?(sync = true) ~r ~c () =
        self#tile ~sync:false ~r ~c ();
        brush#pointer ~sync ~r ~c ()    

    method private annotation ?sync ~r ~c mask =
        let level = annot#current_level in
        match annot#current_layer with
        | '*' -> brush#annotation ?sync ~r ~c level '*'
        | chr -> match mask#active (`CHAR chr) with
            | true  -> brush#annotation ?sync ~r ~c level chr
            | false -> () (* no annotation in this layer. *)

    method private prediction ?sync ~r ~c () =
        if preds#active then
            match preds#max_layer ~r ~c with
            | None -> () (* is that possible? *)
            | Some chr -> let level = annot#current_level in
                match annot#current_layer with
                | '*' -> brush#annotation ?sync ~r ~c level chr
                | cur when chr = cur -> brush#annotation ?sync ~r ~c level chr
                | _ -> () (* Not to be displayed. *)

    method overlay ?(sync = true) ~r ~c () =
        let level = annot#current_level in
        let mask = annot#get ~level ~r ~c () in
        (* Gives priority to annot over preds. *)
        if mask#is_empty () then self#prediction ~sync ~r ~c ()
        else self#annotation ~sync ~r ~c mask

end


let create ~tiles ~brush ~annotations ~predictions () =
    new draw tiles brush annotations predictions
