(* CastANet - cImage.mli *) 

(** Image management. *)

class type image = object

    method ui : ImgTypes.ui
    (** User interface. *)

    method file : ImgTypes.file
    (** File settings. *)

    method source : ImgTypes.source
    (** Source image settings. *)

    method brush : ImgTypes.brush
    (** Drawing toolbox. *)

    method cursor : ImgTypes.cursor
    (** Cursor position manager. *)

    method pointer : ImgTypes.pointer
    (** Mouse pointer tracker. *)

    method small_tiles : ImgTypes.tile_matrix
    (** Small-sized tiles to be used in the right pane. *)

    method large_tiles : ImgTypes.tile_matrix
    (** Large-sized tiles to be used in the left pane. *)

    method annotations : ImgTypes.annotations
    (** User-defined annotations. *)

    method predictions : ImgTypes.predictions
    (** Computer-generated predictions (probabilities). *)

    method predictions_to_annotations : ?erase:bool -> unit -> unit
    (** Converts predictions to annotations. *)

    method show_predictions : unit -> unit
    (** Displays the active prediction layer. *)

    method show : unit -> unit
    (** Displays background, tiles as well as the activate annotation layer. *)

    method mosaic : ?sync:bool -> unit -> unit
    (** Displays the tile matrix. *)

    method magnified_view : unit -> unit
    (** Updates the magnified view. *)

    method update_statistics : unit -> unit

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
