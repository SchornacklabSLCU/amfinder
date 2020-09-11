(* CastANet - cGUI_Levels.mli *)

(** UI auxiliary module dealing with annotation levels. *)

module type S = sig
  val current : unit -> CLevel.t
  (** Returns the active annotation level. *)
  
  val set_current : CLevel.t -> unit
  (** Changes the active annotation level. *)
  
  val radios : (CLevel.t * GButton.radio_button) list 
  (** Radio buttons corresponding to the different annotation types. *)

  val set_callback : (CLevel.t -> GButton.radio_button -> unit) -> unit
  (** Applies a callback function to all radio buttons. *)
end

val make : packing:(GObj.widget -> unit) -> unit -> (module S)
(** Generator function. *)
