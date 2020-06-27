(* CastANet - cEvent.mli *)

(** Event manager. *)

val initialize : unit -> unit
(** Initialize callback functions for all widgets. *)

val update_annotations : GdkEvent.Key.t -> bool
(** Updates toggle button status based on the key pressed. *)
