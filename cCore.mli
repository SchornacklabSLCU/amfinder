(* CastANet - cCore.mli *)

(** CastANet types and constants. *)

type icon_size = [ `SMALL | `LARGE ]
(** The tyoe if icon size. *)

type icon_style = [ `GREY | `RGBA ]
(** The type of icon style. *)

val edge : int

val data_dir : string
(** Directory containing browser data. *)

val icon_dir : string
(** Directory containing icons. *)
