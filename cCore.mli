(* CastANet - cCore.mli *)

(** CastANet types and constants. *)

type size = [ `SMALL | `LARGE ]
(** The tyoe if icon size. *)

type style = [ `GREY | `RGBA ]
(** The type of icon style. *)

val edge : int

val data_dir : string
(** Directory containing browser data. *)

val icon_dir : string
(** Directory containing icons. *)
