(* CastANet - cPixbuf.mli *)

(** Pixbuf auxiliary functions. *)

open GdkPixbuf

val crop : src_x:int -> src_y:int -> edge:int -> pixbuf -> pixbuf
(** Crop. *)

val resize : ?interp:interpolation -> edge:int -> pixbuf -> pixbuf
(** Resize image. *)
