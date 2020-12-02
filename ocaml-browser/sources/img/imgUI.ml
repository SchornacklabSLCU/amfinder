(* amf - imgUI.ml *)


class ui 
  (cursor : ImgTypes.cursor)
  (annotations : ImgTypes.annotations)
  (predictions : ImgTypes.predictions)
   
= object (self)

    val mutable paint_funcs = []

    method set_paint f = paint_funcs <- f :: paint_funcs

    method update () =
        let r, c = cursor#get in
        let annot = annotations#get ~r ~c () in
        AmfUI.Toggles.iter_current (fun chr tog img ->
            (* Annotation is there, but toggle is inactive. *)
            if annot#mem chr && not tog#active then (
                tog#set_active true;
                img#set_pixbuf (AmfIcon.get chr `RGBA `LARGE)
            (* Annotation is missing, but toggle is active. *)
            ) else if annot#off chr && tog#active then (
                tog#set_active false;
                img#set_pixbuf (AmfIcon.get chr `GREY `LARGE)
            )
        )
    
    method private add_annot ?level chr =
        let r, c = cursor#get in
        let annot = annotations#get ?level ~r ~c () in
        annot#add chr;
        self#update ()

    method private rem_annot ?level chr =
        let r, c = cursor#get in
        let annot = annotations#get ?level ~r ~c () in
        annot#add chr;
        self#update ()

    method key_press ev =
        let raw = GdkEvent.Key.string ev in
        if String.length raw > 0 then begin
            let chr = Scanf.sscanf raw "%c" Char.uppercase_ascii in
            match AmfUI.Toggles.is_active chr with
            | None -> () (* Not a valid character. *)
            | Some true -> self#rem_annot chr
            | Some false -> self#add_annot chr
        end;
        List.iter (fun f -> f ()) paint_funcs;
        true (* We do not want focus to move. *)

    method mouse_click (_ : GdkEvent.Button.t) =
        (* Nothing special to do here - cursor has been updated already. *)
        self#update ();
        false

    method toggle (toggle : GButton.toggle_button) chr (_ : GdkEvent.Button.t) =      
        (if toggle#active then self#add_annot else self#rem_annot) chr;
        false

end



let create x y z = new ui x y z
