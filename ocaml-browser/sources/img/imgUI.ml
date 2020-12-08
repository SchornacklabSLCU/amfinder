(* The Automated Mycorrhiza Finder version 1.0 - img/imgUI.ml *)


class ui 
  (cursor : ImgTypes.cursor)
  (annotations : ImgTypes.annotations)
  (predictions : ImgTypes.predictions)
   
= object (self)

    val mutable paint_funcs = []

    method set_paint f = paint_funcs <- f :: paint_funcs

    method update_toggles () =
        let r, c = cursor#get in
        let annot = annotations#get ~r ~c () in
        AmfUI.Toggles.iter_current (fun chr tog img ->
            (* Annotation is there, but toggle is inactive. *)
            if annot#mem chr && not tog#active then (
                tog#set_active true;
                img#set_pixbuf AmfIcon.(get chr Large RGBA)
            (* Annotation is missing, but toggle is active. *)
            ) else if not (annot#mem chr) && tog#active then (
                tog#set_active false;
                img#set_pixbuf AmfIcon.(get chr Large Grayscale)
            )
        )
    
    method private update_annot f chr =
        let r, c = cursor#get in
        let annot = annotations#get ~r ~c () in
        if annot#editable then begin
            f annot chr;
            self#update_toggles ()
        end

    method private add_annot = self#update_annot (fun x c -> x#add ?level:None c) 
    method private rem_annot = self#update_annot (fun x c -> x#remove ?level:None c)

    method key_press ev =
        let raw = GdkEvent.Key.string ev in
        if String.length raw > 0 then begin
            let chr = Scanf.sscanf raw "%c" Char.uppercase_ascii in
            Option.iter (fun is_active ->
                if is_active then self#rem_annot chr
                else self#add_annot chr
            ) (AmfUI.Toggles.is_active chr)
        end;
        List.iter (fun f -> f ()) paint_funcs;
        true (* We do not want focus to move. *)

    method mouse_click (_ : GdkEvent.Button.t) =
        (* Nothing special to do here - cursor has been updated already. *)
        self#update_toggles ();
        false

    method toggle (toggle : GButton.toggle_button) chr (_ : GdkEvent.Button.t) =      
        if toggle#active then self#add_annot chr 
        else self#rem_annot chr;
        false

end



let create x y z = new ui x y z
