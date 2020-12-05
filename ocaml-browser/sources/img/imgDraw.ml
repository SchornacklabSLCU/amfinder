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
        if self#may_update_view ~r ~c () then begin
            match tiles#get ~r ~c with
            | None -> brush#missing_tile ~sync ~r ~c ()
            | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf
        end

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

    method pointer ?(sync = true) ~r ~c () =
        if self#may_update_view ~r ~c () then brush#pointer ~sync ~r ~c ()    

    method private annotation ?sync ~r ~c (mask : AmfAnnot.annot) =
        let level = AmfUI.Levels.current () in
        match AmfUI.Layers.current () with
        (* Display a digest of all annotations. *)
        | '*' -> brush#annotation ?sync ~r ~c level (mask#get ())
        | chr -> match mask#mem chr with
            | true  -> brush#annotation ?sync ~r ~c level (CSet.singleton chr);
            | false -> () (* no annotation in this layer. *)

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
            (* Gives priority to annot over preds. *)
            if mask#is_empty () then self#prediction ~sync ~r ~c ()
            else self#annotation ~sync ~r ~c mask
        end
end


let create a b c d e = new draw a b c d e
