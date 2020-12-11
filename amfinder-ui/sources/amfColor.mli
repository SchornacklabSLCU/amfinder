(* The Automated Mycorrhiza Finder version 1.0 - amfColor.mli *)

(** Color management. *)

type red = float
type blue = float
type green = float
type alpha = float

val opacity : float
(** Alpha channel value used for annotations and predictions. *)

val parse_rgb : string -> red * green * blue
(** [parse_rgb "#rrggbbaa"] returns normalized floating-point values
  * corresponding to the red, green, and blue components of the input
  * color. *)

val parse_rgba : string -> red * green * blue * alpha
(** [parse_rgba "#rrggbbaa"] returns normalized floating-point values
  * corresponding to the red, green, blue, and alpha components of the input
  * color. *)

