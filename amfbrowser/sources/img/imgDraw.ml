(* AMFinder - img/imgDraw.ml
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

open Morelib

class type cls = object
    method tile : ?sync:bool -> r:int -> c:int -> unit -> bool
    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    method overlay : ?sync:bool -> r:int -> c:int -> unit -> unit
end

class draw 
  (tiles : ImgTileMatrix.cls)
  (brush : ImgBrush.cls)
  (cursor : ImgCursor.cls)
  (annot : ImgAnnotations.cls)
  (preds : ImgPredictions.cls) 

= object (self)

    method tile ?(sync = true) ~r ~c () =
        if brush#has_unchanged_boundaries ~r ~c () then (
            (* TODO: Is None a possible case? *)
            match tiles#get ~r ~c with
            | None -> brush#empty ~sync ~r ~c (); false
            | Some pixbuf -> brush#pixbuf ~sync ~r ~c pixbuf; true
        ) else true

    method cursor ?(sync = true) ~r ~c () =
        if brush#has_unchanged_boundaries ~r ~c () then
            brush#cursor ~sync ~r ~c ();
        if preds#active then (
            let level = AmfUI.Levels.current () in
            let mask = annot#get ~r ~c () in
            if mask#is_empty () then
                Option.iter (fun t ->
                    let chr = AmfUI.Layers.current () in
                    if chr <> '*' then
                        AmfLevel.char_index level chr
                        |> List.nth t
                        |> brush#show_probability ~sync
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
                brush#prediction ?sync ~r ~c t chr
            ) (preds#get ~r ~c)

    method overlay ?(sync = true) ~r ~c () =
        if brush#has_unchanged_boundaries ~r ~c () then begin
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
