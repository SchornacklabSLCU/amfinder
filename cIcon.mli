(* CastANet - cIcon.mli *)

(** CastANet icons. *)

type size = [
  | `SMALL          (** Small icons, 24x24 pixels. *)
  | `LARGE          (** Large icons, 48x48 pixels. *)
]
(** Available icon sizes.  *)

type style = [
  | `RGBA           (** Active, coloured icons. *)
  | `RGBA_LOCKED    (** Same, but locked.       *)
  | `GREY           (** Inactive, grey icons.   *)
  | `GREY_LOCKED    (** Same, but locked.       *)
]
(** Available icon styles. *)

val get : char -> style -> size -> GdkPixbuf.pixbuf
(** [get chr sty sz] returns a GdkPixbuf corresponding to icon [chr], of 
  * style [sty] and size [sz].
  $ @raise Invalid_argument if [chr] is not a valid character. *)
