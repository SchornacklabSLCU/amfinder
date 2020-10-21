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

type palette = [
  | `CIVIDIS 
  | `VIRIDIS 
  | `PLASMA
]
(** Available color palettes. *)

val get_palette : palette -> size -> GdkPixbuf.pixbuf
(** Returns a palette icon. *)

val get : char -> style -> size -> GdkPixbuf.pixbuf
(** [get chr sty sz] returns a GdkPixbuf corresponding to icon [chr], of 
  * style [sty] and size [sz].
  $ @raise Invalid_argument if [chr] is not a valid character. *)


(** Miscellaneous icons. *)
module Misc : sig

    val cam : style -> GdkPixbuf.pixbuf
    (** Icon for class activation maps. *)

    val conv : GdkPixbuf.pixbuf
    (** Icon for conversion of predictions to annotations. *)

    val palette : GdkPixbuf.pixbuf
    (** Icon for color palettes. *)

    val show_preds : GdkPixbuf.pixbuf
    (** Add predictions. *)
    
    val hide_preds : GdkPixbuf.pixbuf
    (** Remove predictions. *)

end
