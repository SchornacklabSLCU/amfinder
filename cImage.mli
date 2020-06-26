(* CastANet - cImage.mli *)

(** Mycorrhiza scans, loaded as mosaics of tiles. *)

type t
(** The type for images. *)

type tile_size = [ `LARGE | `SMALL ]
(** Size of individual tiles. [`LARGE] is for zoomed in display, while [`SMALL]
  * corresponds to image thumbnail. *)

val create : ui_width:int -> ui_height:int -> string -> t
(** Create a new image from the given path. *)

val path : t -> string
(** Original image path. *)

val original_width : t -> int
(** Original width (in pixels) of the image. *)

val original_height : t -> int
(** Original height (in pixels) of the image. *)

val xini : t -> int
(** Returns the X axis origin, in pixels. *)

val yini : t -> int
(** Returns the Y axis origin, in pixels. *)

val rows : t -> int
(** Returns the row count. *)

val columns : t -> int
(** Returns the column count. *)

val is_valid : r:int -> c:int -> t -> bool
(** Tells whether the given coordinates are valid. *)

val edge : t -> tile_size -> int
(** Returns tile edge, in pixels. *)

val x : c:int -> t -> tile_size -> int
(** Returns the X-axis pixel value corresponding to the given colum,. *)

val y : r:int -> t -> tile_size -> int
(** Returns the Y-axis pixel value corresponding to the given row. *)

val tiles : t -> tile_size -> GdkPixbuf.pixbuf array array
(** Returns small/large tile pixbufs. *)

val tile : r:int -> c:int -> t -> tile_size -> GdkPixbuf.pixbuf option
(** Convenience function to retrieve a given tile. *) 

val annotations : t -> CAnnot.t array array
(** Returns tile annotations. *)

val annotation : r:int -> c:int -> t -> CAnnot.t option
(** Convenience function to retrieve a specific annotation. *)

val cursor_pos : t -> int * int
(** [cursor_pos img] returns the current cursor position in image [img]. *)

val set_cursor_pos : t -> int * int -> unit
(** Modifies cursor position. *)

val iter_tiles :
  (int -> int -> GdkPixbuf.pixbuf -> unit) -> t -> tile_size -> unit
(** Iter over tiles. *)

val iter_annotations : (int -> int -> CAnnot.t -> unit) -> t -> unit
(** Iter over annotations. *)

val digest : t -> string
(** Human-readable digest with the main parameters of the given image.
  * Uses Pango markup formatting. *)
