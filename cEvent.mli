(* CastANet - cEvent.mli *)

(** Event manager. *)

val initialize : unit -> (char * GButton.toggle_button * GtkSignal.id) array
(** Initialize callback functions for all widgets. *)

val update_annotations : GdkEvent.Key.t -> bool
(** Updates toggle button status based on the key pressed. *)
