(* CastANet - cImage.mli *)

(** Mycorrhiza scans, loaded as mosaics of tiles. *)

type t
(** The type for images. *)

val create : ui_width:int -> ui_height:int -> string -> t
(** Create a new image from the given path. *)

val path : t -> string
(** Original image path. *)

val basename : t -> string
(** Image file name. *)

val dirname : t -> string
(** Image folder. *)

val original_size : t -> int * int
(** Returns the original size of the image ([(w, h)], in pixels). *)

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

val edge : t -> CCore.size -> int
(** Returns tile edge, in pixels. *)

val x : c:int -> t -> CCore.size -> int
(** Returns the X-axis pixel value corresponding to the given column. *)

val y : r:int -> t -> CCore.size -> int
(** Returns the Y-axis pixel value corresponding to the given row. *)

val tiles : t -> CCore.size -> GdkPixbuf.pixbuf CExt.Matrix.t
(** Returns small/large tile pixbufs. *)

val tile : r:int -> c:int -> t -> CCore.size -> GdkPixbuf.pixbuf option
(** Convenience function to retrieve a given tile. *) 

val annotations : t -> CAnnot.t CExt.Matrix.t
(** Returns tile annotations. *)

val annotation : r:int -> c:int -> t -> CAnnot.t option
(** Convenience function to retrieve a specific annotation. *)

val statistics : t -> (char * int) list
(** Returns the count of all annotations within the given image. *)

val cursor_pos : t -> int * int
(** [cursor_pos img] returns the current cursor position in image [img]. *)

val set_cursor_pos : t -> int * int -> unit
(** Modifies cursor position. *)

val iter_tiles :
  (int -> int -> GdkPixbuf.pixbuf -> unit) -> t -> CCore.size -> unit
(** Iter over tiles. *)

val iter_annot : (int -> int -> CAnnot.t -> unit) -> t -> unit
(** Iter over annotations. *)

val digest : t -> string
(** Human-readable digest with the main parameters of the given image.
  * Uses Pango markup formatting. *)
