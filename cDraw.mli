(* CastANet - cDraw.mli *)

(** Thumbnail drawing. *)

val load : string -> unit
(** Loads an image. *)

val curr_image : unit -> CImage.t
(** Returns the current image. *)

val set_curr_annotation : bool -> char -> unit
(** Updates current annotation. *)

val cursor : ?sync:bool -> unit -> unit
(** Display the cursor. *)

val active_layer : ?sync:bool -> unit -> unit
(** Display the active annotation layer of the current image. *)

val display_set : unit -> unit
(** Display all tiles that belong to the current layer. *)

(** Interaction between drawing and the graphical user interface. *)
module GUI : sig
  val magnified_view : unit -> unit
  (** Displays magnified view. *)
end

(** Keyboard- and mouse-responsive cursor drawing functions. *)
module Cursor : sig
  val arrow_key_press :
    ?toggles:(char * GButton.toggle_button * GtkSignal.id) array ->
    GdkEvent.Key.t -> bool
  (** Moves the cursor when an arrow key is pressed. *)
  val at_mouse_pointer : 
    ?toggles:(char * GButton.toggle_button * GtkSignal.id) array ->
    GdkEvent.Button.t -> bool
  (** Move the cursor to the mouse pointer. *)
end

(** Drawing functions related to mouse pointer. *)
module MouseTracker : sig
  val update : GdkEvent.Motion.t -> bool
  (** Displays a light-red tile below the mouse pointer to tell users they can
    * move the cursor with a mouse click. *)
  val hide : 'a -> bool
  (** Removes the light-red tile for the mouse pointer is leaving the drawing 
    * area. *)
end
