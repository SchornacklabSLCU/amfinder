(** amf - imgDraw.ml *)

class draw 
  (tiles : ImgTypes.tile_matrix)
  (brush : ImgTypes.brush)
  (cursor : ImgTypes.cursor)
  (annot : ImgTypes.annotations)
  (preds : ImgTypes.predictions) 

= object (self)

    val mutable update_funcs : (unit -> unit) list = []

    method set_update f = update_funcs <- f :: update_funcs

    method private may_update_view ~r ~c () =
        if brush#make_visible ~r ~c () then (
            List.iter (fun f -> f ()) update_funcs;
            false
        ) else true

    method tile ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then begin
            match tiles#get ~r ~c with
            | None -> AmfLog.error ~code:Err.out_of_bounds "ImgDraw.draw#tile: \
                Index out of bounds (r = %d, c = %d)" r c
            | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf
        end

    method cursor ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then begin
            brush#cursor ~sync ~r ~c ();
            (*
            if preds#active then (
                let level = annot#current_level in
                let mask = annot#get ~level ~r ~c () in
                if mask#is_empty then
                    Option.iter (fun t ->
                        let chr = annot#current_layer in
                        if chr <> '*' then annot#current_level
                        |> (fun x -> AmfLevel.char_index x chr)
                        |> List.nth t
                        |> brush#show_probability ~sync:true
                    ) (preds#get ~r ~c)
            )*)
        end

    method pointer ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then brush#pointer ~sync ~r ~c ()    

    method private annotation ?sync ~r ~c mask =
        let level = annot#current_level in
        match annot#current_layer with
        | '*' -> brush#annotation ?sync ~r ~c level '*'
        | chr -> match mask#mem chr with
            | true  -> brush#annotation ?sync ~r ~c level chr
            | false -> () (* no annotation in this layer. *)

    (*  *)
    method private prediction ?sync ~r ~c () =
        if preds#active then
            Option.iter (fun t ->
                let chr = annot#current_layer in
                if chr = '*' then brush#pie_chart ?sync ~r ~c t
                else annot#current_level
                    |> (fun x -> AmfLevel.char_index x chr)
                    |> List.nth t
                    |> brush#prediction ~sync:false ~r ~c chr
            ) (preds#get ~r ~c)

    method overlay ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then begin
            let level = annot#current_level in
            let mask = annot#get ~level ~r ~c () in
            (* Gives priority to annot over preds. *)
            if mask#is_empty then self#prediction ~sync ~r ~c ()
            else self#annotation ~sync ~r ~c mask
        end
end


let create a b c d e = new draw a b c d e
