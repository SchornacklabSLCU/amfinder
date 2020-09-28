(* CastANet - cImage.mli *) 

(** Image management. *)

class type image = object
    method file : ImgFile.t
    (** File settings. *)

    method source : ImgSource.t
    (** Source image settings. *)

    method draw : ImgDraw.t
    (** Drawing toolbox. *)

    method small_tiles : ImgTileMatrix.t
    (** Small-sized tiles to be used in the right pane. *)

    method large_tiles : ImgTileMatrix.t
    (** Large-sized tiles to be used in the left pane. *)

    method annotations : CTable.annotation_table list
    (** User-defined annotations. *)

    method predictions : CTable.prediction_table list
    (** Computer-generated predictions (probabilities). *)
end

val load : edge:int -> string -> image
(** [load ~edge:n img] loads image [img], using squares of [n]x[n] pixels 
  * as tiles.
  * @raise Invalid_argument if the file does not exist. *)
