(* CastANet - cImage.mli *) 

(** Image management. *)

class type image = object

    method file : ImgFile.file
    (** File settings. *)

    method source : ImgSource.source
    (** Source image settings. *)

    method brush : ImgBrush.brush
    (** Drawing toolbox. *)

    method cursor : ImgCursor.cursor
    (** Cursor position manager. *)

    method pointer : ImgPointer.pointer
    (** Mouse pointer tracker. *)

    method small_tiles : ImgTileMatrix.tile_matrix
    (** Small-sized tiles to be used in the right pane. *)

    method large_tiles : ImgTileMatrix.tile_matrix
    (** Large-sized tiles to be used in the left pane. *)

    method annotations : ImgAnnotations.annotations
    (** User-defined annotations. *)

    method predictions : ImgPredictions.predictions
    (** Computer-generated predictions (probabilities). *)

    method show_predictions : unit -> unit
    (** Displays the active prediction layer. *)

    method show : unit -> unit
    (** Displays background, tiles as well as the activate annotation layer. *)

    method mosaic : ?sync:bool -> unit -> unit
    (** Displays the tile matrix. *)

    method magnified_view : unit -> unit
    (** Updates the magnified view. *)

    method at_exit : (unit -> unit) -> unit
    (** Registers a function to be run before the image gets destroyed. *)

    method save : unit -> unit
    (** Saves the current image. *)
    
    method screenshot : unit -> unit
    (** Saves a screenshot of the current magnified view. *)

end

val create : edge:int -> string -> image
(** [load ~edge:n path] loads image [path], using [n]x[n] squares as tiles.
  * @raise Invalid_argument if the file does not exist. *)
