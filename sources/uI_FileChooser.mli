(* CastANet - uI_FileChooser.mli *)

module type PARAMS = sig
  val parent : GWindow.window
  val title : string
  val border_width : int
end

module type S = sig
  val jpeg : GFile.filter
  (** File filter for JPEG images. *)
  
  val tiff : GFile.filter
  (** File filter for TIFF images. *)

  val run : unit -> string
  (** Displays a dialog window to select the image to open (if not provided
    * on the command line). The program terminates if no image is selected. *)
end

module Make : PARAMS -> S
(** Generator. *)
