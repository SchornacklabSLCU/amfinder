(* AMFinder - img/imgUI.ml
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

    method private add_annot =
        self#update_annot (fun (x : AmfAnnot.annot) c -> x#add c) 
    method private rem_annot =
        self#update_annot (fun (x : AmfAnnot.annot) c -> x#remove c)

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

    method toggle
      (tog : GButton.toggle_button)
      (ico : GMisc.image) chr (_ : GdkEvent.Button.t) =
        (* Edits annotation. *)   
        begin match tog#active with
            | true  -> self#rem_annot chr
            | false -> self#add_annot chr
        end;
        (* Update the toggle buttons. *)
        self#update_toggles ();
        (* Refresh the tile display. *)
        List.iter (fun f -> f ()) paint_funcs;
        (* Nothing else to do, changes have been made. *)
        true

end



let create x y z = new ui x y z
