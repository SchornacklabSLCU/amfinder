(* CastANet - cAction.mli *)

(** Integrated actions. *)

val load_image : (char * GButton.toggle_button * GtkSignal.id) array -> unit
(** Loads an image and initializes the user interface. This function also saves
  * and removes the previously opened image, if any. *)
