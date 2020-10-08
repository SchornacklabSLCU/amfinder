(* CastANet Browser - imgPointer.mli *)

(** Mouse pointer events. *)

class type pointer = object
    method get : (int * int) option
    (** Returns the current pointer position, if any. *)

    method at : r:int -> c:int -> bool
    (** Tells whether the pointer is at a given coordinate. *)

    method track : GdkEvent.Motion.t -> bool
    (** Tracks pointer position. *)

    method leave : GdkEvent.Crossing.t -> bool
    (** Detects pointer leaving. *)

    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below pointer. *)

    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the pointer. *)
end


val create : ImgSource.source -> ImgBrush.brush -> pointer
(** Builder. *)
