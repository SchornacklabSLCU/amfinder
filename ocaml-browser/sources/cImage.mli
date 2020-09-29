(* CastANet - cImage.mli *) 

(** Image management. *)

class type image = object

    method file : ImgFile.t
    (** File settings. *)

    method source : ImgSource.t
    (** Source image settings. *)

    method paint : ImgPaint.t
    (** Drawing toolbox. *)

    method cursor : ImgCursor.t
    (** Cursor position manager. *)

    method pointer : ImgPointer.t
    (** Mouse pointer tracker. *)

    method small_tiles : ImgTileMatrix.t
    (** Small-sized tiles to be used in the right pane. *)

    method large_tiles : ImgTileMatrix.t
    (** Large-sized tiles to be used in the left pane. *)

    method annotations : CMask.layered_mask ImgDataset.t
    (** User-defined annotations. *)

    method predictions : float list ImgDataset.t
    (** Computer-generated predictions (probabilities). *)

    method show : unit -> unit
    (** Displays background, tiles as well as the activate annotation layer. *)

    method at_exit : (unit -> unit) -> unit
    (** Registers a function to be run before the image gets destroyed. *)

    method save : unit -> unit
    (** Saves the current image. *)

end

val create : edge:int -> string -> image
(** [load ~edge:n img] loads image [img], using [n]x[n] squares as tiles.
  * @raise Invalid_argument if the file does not exist. *)
