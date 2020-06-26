(* CastANet - cIcon.mli *)

(** CastANet custom icons. *)

type icon_type = [ `RGBA | `GREY ]
(** Color ([`RGBA]) or grayscale ([`GREY]) icon types. *)

type icon_size = [ `LARGE | `SMALL ]
(** Icons can be either large (48 x 48 pixels) or small (24 x 24 pixels). *)

val get : ?grad:bool -> char -> icon_type -> icon_size -> GdkPixbuf.pixbuf
(** Retrieve a particular icon, given its name, type and size. The optional
  * parameter tells whether the icon can be turned into a gradient. *)

val get_special : icon_type -> icon_size -> GdkPixbuf.pixbuf
(** Special icons (i.e. the icon ["Any"]). *)
