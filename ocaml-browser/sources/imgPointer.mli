(* CastANet Browser - imgPointer.mli *)

(** Mouse pointer events. *)

class type t = object
    method get : (int * int) option
    (** Returns the current pointer position, if any. *)

    method track : GdkEvent.Motion.t -> bool
    (** Tracks pointer position. *)

    method leave : GdkEvent.Crossing.t -> bool
    (** Detects pointer leaving. *)

    method set_erase : (r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below pointer. *)

    method set_paint : (r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the pointer. *)
end


val create : ImgSource.t -> ImgPaint.t -> t
(** Builder. *)
