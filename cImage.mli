(* CastANet - cImage.mli *) 

open CExt

type t

val get_active : unit -> t option

val rem_active : unit -> unit

val path : t -> string

val basename : t -> string

val dirname : t -> string

val source : t -> [`W | `H] -> int

val origin : t -> [`X | `Y] -> int

val dim : t -> [`R | `C] -> int

val annotations : t -> CTable.table

val edge : t -> [`SMALL | `LARGE] -> int

val tiles : t -> [`SMALL | `LARGE] -> GdkPixbuf.pixbuf Ext_Matrix.t

val tile : r:int -> c:int -> t -> [`SMALL | `LARGE] -> GdkPixbuf.pixbuf option

val x : c:int -> t -> [`SMALL | `LARGE] -> int

val y : r:int -> t -> [`SMALL | `LARGE] -> int

val cursor_pos : t -> int * int

val set_cursor_pos : t -> int * int -> unit

val iter_tiles : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> t -> [`SMALL | `LARGE] -> unit

val statistics : t -> CLevel.t -> (char * int) list

val create : ?edge:int -> string -> t
