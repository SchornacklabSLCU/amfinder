(* CastANet - imgCursor.mli *)

(** Cursor management. *)

class type t = object
    method cursor_pos : int * int
    (** Returns the current cursor position. *)

    method set_cursor_pos : int * int -> unit
    (** Changes the current cursor position. *)

    method move_left : ?jump:int -> unit -> unit
    (** Moves the cursor to the left. *)

    method move_right : ?jump:int -> unit -> unit
    (** Moves the cursor to the right. *)

    method move_up : ?jump:int -> unit -> unit
    (** Moves the cursor to the top. *)

    method move_down : ?jump:int -> unit -> unit
    (** Moves the cursor to the bottom. *)

end

val create : ImgSource.t -> t
(** Builder. *)
