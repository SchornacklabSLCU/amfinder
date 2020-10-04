(* CastANet - imgCursor.mli *)

(** Cursor management. *)

class type cursor = object

    method get : int * int
    (** Returns the current cursor position. *)

    method at : r:int -> c:int -> bool
    (** Indicates whether the cursor is at the given coordinates. *)

    method key_press : GdkEvent.Key.t -> bool
    (** Monitors key press. *)

    method mouse_click : GdkEvent.Button.t -> bool
    (** Monitors mouse click. *)

    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below cursor. *)

    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the cursor. *)

end

val create : ImgSource.source -> ImgPaint.paint -> cursor
(** Builder. *)
