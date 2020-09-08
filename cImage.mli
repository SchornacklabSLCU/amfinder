(* CastANet - cImage.mli *)

(** CastANet image manager. *)

val load : unit -> unit
(** Loads the image given on the command line, or displays a file chooser
  * dialogue window where the user can select the image file to open.
  * The application terminates if no file is selected (see module [CGUI]). *)

val save : unit -> unit
(** Save the current annotations, if any. *)

val initialize : unit -> unit
(** Initialize callbacks. *)
