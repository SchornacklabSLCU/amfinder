(* The Automated Mycorrhiza Finder version 1.0 - img/imgDraw.ml *)

open Morelib

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
            List.iter (fun f ->  f ()) update_funcs;
            false
        ) else true

    method tile ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then (
            (* TODO: Is None a possible case? *)
            match tiles#get ~r ~c with
            | None -> brush#empty ~sync ~r ~c (); false
            | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf; true
        ) else true

    method cursor ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then brush#cursor ~sync ~r ~c ();
        if preds#active then (
            let level = AmfUI.Levels.current () in
            let mask = annot#get ~r ~c () in
            if mask#is_empty () then
                Option.iter (fun t ->
                    let chr = AmfUI.Layers.current () in
                    if chr <> '*' then level
                    |> (fun x -> AmfLevel.char_index x chr)
                    |> List.nth t
                    |> (fun x -> brush#show_probability ~sync x)
                ) (preds#get ~r ~c)
        )

    (* Draws annotations.
       (a) Shows all annotation types.
       (b) Shows a single annotation type.
       (c) Removes probability, if any, given that the cell has annotation.
       (d) Ignore cells without annotation at the given level.
       (e) Shows annotation corresponding to the given layer.
       (f) Shows a barred eye symbol. An annotation exists at a different layer. 
     *)
    method private annotation ?sync ~r ~c (mask : AmfAnnot.annot) =
        let level = AmfUI.Levels.current () in
        match AmfUI.Layers.current () with
        | '*' (* a *) -> brush#annotation ?sync ~r ~c level (mask#get ())
        | chr (* b *) ->
            if cursor#at ~r ~c then (* c *) brush#hide_probability ();
            if (* d *) not (mask#is_empty ~level ()) then
                if mask#mem chr then (* e *)
                    brush#annotation ?sync ~r ~c level (CSet.singleton chr)
                else (* f *)
                    brush#annotation_other_layer ?sync ~r ~c ()

    (*  *)
    method private prediction ?sync ~r ~c () =
        if preds#active then
            Option.iter (fun t ->
                let chr = AmfUI.Layers.current () in
                if chr = '*' then brush#pie_chart ?sync ~r ~c t else
                    let x = AmfUI.Levels.current ()
                        |> (fun x -> AmfLevel.char_index x chr)
                        |> List.nth t
                    in (brush#prediction ?sync ~r ~c chr x);
            ) (preds#get ~r ~c)

    method overlay ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then begin
            let mask = annot#get ~r ~c () in
            (* IR mode is only available to tiles with mycorrhiza structures. *)
            if mask#editable then (
                (* Gives priority to annotations over predictions. *)
                if mask#is_empty () then self#prediction ~sync ~r ~c ()
                else self#annotation ~sync ~r ~c mask
            ) else brush#locked_tile ~sync ~r ~c ()
        end
end


let create a b c d e = new draw a b c d e
