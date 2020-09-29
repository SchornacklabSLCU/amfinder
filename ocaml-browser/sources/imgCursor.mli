(* CastANet - imgCursor.mli *)

(** Cursor management. *)

class type t = object

    method get : int * int
    (** Returns the current cursor position. *)

    method key_press : GdkEvent.Key.t -> bool
    (** Monitors key press. *)

    method mouse_click : GdkEvent.Button.t -> bool
    (** Monitors mouse click. *)

    method set_erase : (r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below cursor. *)

    method set_paint : (r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the cursor. *)

end

val create : ImgSource.t -> ImgPaint.t -> t
(** Builder. *)
