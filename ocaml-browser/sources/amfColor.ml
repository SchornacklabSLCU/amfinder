(* The Automated Mycorrhiza Finder version 1.0 - amfColor.ml *)

open Scanf

type red = float
type blue = float
type green = float
type alpha = float

let opacity = float 0xB0 /. 255.0

let parse_rgb =
    let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
    fun s -> sscanf s "#%02x%02x%02x" (fun r g b -> f r, f g, f b)

let parse_rgba =
    let f n = max 0.0 @@ min 1.0 @@ float n /. 255.0 in
    fun s -> sscanf s "#%02x%02x%02x%02x" (fun r g b a -> f r, f g, f b, f a)

