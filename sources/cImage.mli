(* CastANet - cImage.mli *) 

open CExt

type image
(** The type for CastANet images. *)

val get_active : unit -> image option

val rem_active : unit -> unit

val path : image -> string
(** Path to the loaded image. *)

val basename : image -> string

val dirname : image -> string

val source : image -> [`W | `H] -> int

val origin : image -> [`X | `Y] -> int

val dim : image -> [`R | `C] -> int

val annotations : image -> CTable.table

val edge : image -> [`SMALL | `LARGE] -> int

val tiles : image -> [`SMALL | `LARGE] -> GdkPixbuf.pixbuf Ext_Matrix.t

val tile : r:int -> c:int -> image -> [`SMALL | `LARGE] -> GdkPixbuf.pixbuf option

val x : c:int -> image -> [`SMALL | `LARGE] -> int

val y : r:int -> image -> [`SMALL | `LARGE] -> int

val iter_tiles : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> image -> [`SMALL | `LARGE] -> unit

val statistics : image -> CLevel.t -> (char * int) list

val create : ?edge:int -> string -> image
