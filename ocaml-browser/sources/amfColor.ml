(* The Automated Mycorrhiza Finder version 1.0 - amfColor.ml *)

open Scanf

type red = float
type blue = float
type green = float
type alpha = float

let opacity = float 0xB0 /. 255.0

let rgb_from_name = function
    | "cyan"    -> "#00FFFF" 
    | "white"   -> "#FFFFFF"
    | "yellow"  -> "#FFFF00"
    | "magenta" -> "#FF00FF"
    | other     -> other

let rgba_from_name x = 
    let res = rgb_from_name x in
    if res = x then res else (* was a name *) res ^ "FF"

let normalize n = max 0.0 (min 1.0 (float n /. 255.0))

let parse_rgb s =
    sscanf (rgb_from_name s) "#%02x%02x%02x"
        (fun r g b -> normalize r, normalize g, normalize b)

let parse_rgba s =
    sscanf (rgba_from_name s) "#%02x%02x%02x%02x" 
        (fun r g b a -> normalize r, normalize g, normalize b, normalize a)
