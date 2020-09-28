(* CastANet - cImage.mli *) 

(** Image management. *)

class type t = object

    method file : ImgFile.t
    (** File settings. *)

    method source : ImgSource.t
    (** Source image settings. *)

    method draw : ImgDraw.t
    (** Drawing toolbox. *)

    method cursor : ImgCursor.t
    (** Cursor position manager. *)

    method small_tiles : ImgTileMatrix.t
    (** Small-sized tiles to be used in the right pane. *)

    method large_tiles : ImgTileMatrix.t
    (** Large-sized tiles to be used in the left pane. *)

    method annotations : CTable.annotation_table list
    (** User-defined annotations. *)

    method predictions : CTable.prediction_table list
    (** Computer-generated predictions (probabilities). *)

end

val load : edge:int -> string -> t
(** [load ~edge:n img] loads image [img], using [n]x[n] squares as tiles.
  * @raise Invalid_argument if the file does not exist. *)
