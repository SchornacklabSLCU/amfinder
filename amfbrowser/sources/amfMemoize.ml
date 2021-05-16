(* AMFinder - amfMemoize.ml
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

open AmfConst

(* Description:
 * (a) Creates an empty association table for memoization (<store>).
 * (b) Defines the initial function returned by <create>.
 * (c) If the input value <x> is absent from the table <store>. 
 * (d) Computes the actual result (<y = f x>).
 * (e) Stores the result in <store> using <x> as key.
 * (f) Returns the result.
 * (g) If <x> is part of <store>, returns the saved result. *)
let create f =
    let store = ref [] (* a *) in
    fun x -> (* b *)
        match List.assoc_opt x !store with
        | None (* c *)-> let y = f x (* d *) in
            store := (x, y) :: !store; (* e *)
            y (* f *)
        | Some y (* g *) -> y

let cursor = create AmfSurface.Annotation.cursor
let dashed_square = create AmfSurface.Annotation.dashed
let locked_square = create AmfSurface.Annotation.locked
let empty_square = create (AmfSurface.Annotation.empty "#808080FF")

let palette =
    (fun index ->
        AmfUI.Predictions.get_colors ()
        |> (fun t -> Array.get t index)
        |> (fun color -> (AmfSurface.Prediction.filled color))
    )

let make_surface ?grayscale level chr x =
    AmfLevel.icon_text level
    |> List.assoc_opt chr
    |> (fun symbol -> (level, chr),
        create (AmfSurface.Annotation.filled ?symbol ?grayscale x))

let layers =
    List.map AmfLevel.(fun x ->
        List.map2 (make_surface x) (to_header x) (colors x)
    ) AmfLevel.all
    |> List.flatten

let gray_layers =
    List.map AmfLevel.(fun x ->
        List.map2 (make_surface ~grayscale:true x) (to_header x) (colors x)
    ) AmfLevel.all
    |> List.flatten

let layer level chr = List.assoc (level, chr) layers
