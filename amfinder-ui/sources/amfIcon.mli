(* The Automated Mycorrhiza Finder version 1.0 - amfIcon.mli *)

(** Interface icons. *)

(** Icon size.  *)
type size = 
    | Small (** Small icons, 24 x 24 pixels. *)
    | Large (** Large icons, 48 x 48 pixels. *)


(** Color mode. *)
type style = 
    | Grayscale     (** Gray levels. *)
    | RGBA          (** Color mode (with alpha channel). *)


val get : char -> size -> style -> GdkPixbuf.pixbuf
(** [get chr sty sz] returns a GdkPixbuf corresponding to icon [chr], of 
  * style [sty] and size [sz]. @raise Invalid_argument if [chr] is not a 
  * valid character. *)


(** Miscellaneous icons. *)
module Misc : sig
    val cam : style -> GdkPixbuf.pixbuf
    (** Icon for class activation maps. *)

    val conv : GdkPixbuf.pixbuf
    (** Icon for conversion of predictions to annotations. *)

    val ambiguities : GdkPixbuf.pixbuf
    (** Icon to move cursor to ambiguous predictions. *)

    val palette : GdkPixbuf.pixbuf
    (** Icon for color palettes. *)

    val erase : GdkPixbuf.pixbuf
    (** Icon for eraser. *)

    val snapshot : GdkPixbuf.pixbuf
    (** Icon for snapshot. *)

    val show_preds : GdkPixbuf.pixbuf
    (** Add predictions. *)
    
    val hide_preds : GdkPixbuf.pixbuf
    (** Remove predictions. *)
end
