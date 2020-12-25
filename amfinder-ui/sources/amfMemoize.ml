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



let create f =
    let tbl = ref [] in
    fun x ->
        match List.assoc_opt x !tbl with
        | None -> let res = f x in
            tbl := (x, res) :: !tbl;
            res
        | Some res -> res

let cursor = create (AmfSurface.Annotation.cursor "#CC0000FF")
let dashed_square = create (AmfSurface.Annotation.dashed "#000000FF")
let locked_square = create (AmfSurface.Annotation.locked "#80808090")
let empty_square = create (AmfSurface.Annotation.empty "#808080FF")

let palette =
    create (fun index ->
        AmfUI.Predictions.get_colors ()
        |> (fun t -> Array.get t index)
        |> (fun color -> create (AmfSurface.Prediction.filled color))
    )

let make_surface level chr x =
    AmfLevel.icon_text level
    |> List.assoc_opt chr
    |> (fun symbol -> (level, chr), create (AmfSurface.Annotation.filled ?symbol x))

let layers =
    List.map AmfLevel.(fun x ->
        List.map2 (make_surface x) (to_header x) (colors x)
    ) AmfLevel.all
    |> List.flatten

let layer level chr = List.assoc (level, chr) layers
