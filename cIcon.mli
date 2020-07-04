(* CastANet - cIcon.mli *)

(** CastANet custom icons. *)

val get : ?grad:bool -> char -> CCore.style -> CCore.size -> GdkPixbuf.pixbuf
(** Retrieve a particular icon, given its name, type and size. The optional
  * parameter tells whether the icon can be turned into a gradient. To retrieve
  * the joker icon, use ['*'] as input character. *)
