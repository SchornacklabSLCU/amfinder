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

class type cls = object
    method set_paint : (unit -> unit) -> unit
    method update_toggles : unit -> unit
    method toggle :
        GButton.toggle_button ->
        GMisc.image -> char -> GdkEvent.Button.t -> bool
    method key_press : GdkEvent.Key.t -> bool
    method mouse_click : GdkEvent.Button.t -> bool
end


class ui 
  (cursor : ImgCursor.cls)
  (annotations : ImgAnnotations.cls)
  (predictions : ImgPredictions.cls)
   
= object (self)

    val mutable paint_funcs = []

    method private current_annot =
        let r, c = cursor#get in
        annotations#get ~r ~c ()

    method private redraw () =
        List.iter (fun f -> f ()) paint_funcs

    method private update_and_redraw ~is_add chr =
        let cur = self#current_annot in
        if cur#editable then begin
            (* Edits annotation.       *)
            if is_add then cur#add chr else cur#remove chr;
            (* Updates toggle buttons and redraws current tile. *)
            self#update_toggles ();
            self#redraw ();
        end

    method set_paint f = paint_funcs <- f :: paint_funcs

    method update_toggles () =
        let update_toggle chr tog img =
            (* Annotation is set but toggle is inactive. *)
            if not tog#active && self#current_annot#mem chr  then
            begin
                tog#set_active true;
                img#set_pixbuf AmfIcon.(get chr Large RGBA)
            end
            (* Annotation is not set but toggle is active. *)
            else if tog#active && not (self#current_annot#mem chr) then
            begin
                tog#set_active false;
                img#set_pixbuf AmfIcon.(get chr Large Grayscale)
            end
        in AmfUI.Toggles.iter_current update_toggle

    method key_press ev = 
        if self#current_annot#editable then (
            if GdkEvent.Key.keyval ev = 65535 (* delete *) then (   
                self#current_annot#erase (); 
                self#update_toggles ();
                self#redraw ()
            ) else (
                let raw = GdkEvent.Key.string ev in
                (* Edits annotation. *)
                if String.length raw > 0 then (
                    let chr = Scanf.sscanf raw "%c" Char.uppercase_ascii in
                    Option.iter (fun active ->
                        if active then self#current_annot#remove chr
                        else self#current_annot#add chr;
                        self#update_toggles ();
                        self#redraw ();
                    ) (AmfUI.Toggles.is_active chr);
                )
            )
        );
        (* To make sure focus does not move. *)
        true

    method toggle
      (tog : GButton.toggle_button)
      (ico : GMisc.image) chr (_ : GdkEvent.Button.t) =
        (* Edits annotation. *)
        self#update_and_redraw ~is_add:(not tog#active) chr;
        (* Nothing else to do, changes have been made. *)
        true

    method mouse_click (_ : GdkEvent.Button.t) =
        (* There is no need to redraw the current tile. *)
        self#update_toggles ();
        false

end



let create c a p = new ui c a p
