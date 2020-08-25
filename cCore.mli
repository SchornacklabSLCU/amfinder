(* CastANet - cCore.mli *)

(** CastANet types and constants. *)

type icon_size = [ `SMALL | `LARGE ]
(** The tyoe if icon size. *)

type icon_style = [ `GREY | `RGBA ]
(** The type of icon style. *)

type annotation_type = [ `COLONIZATION | `ARB_VESICLES | `ALL_FEATURES ]
(** The type of annotation styles. *)

val available_annotation_types : annotation_type list
(** The list of all available annotation types. *)

val edge : int

val data_dir : string
(** Directory containing browser data. *)

val icon_dir : string
(** Directory containing icons. *)
