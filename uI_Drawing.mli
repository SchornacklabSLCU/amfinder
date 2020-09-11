(* CastANet - uI_Drawing.mli *)

module type PARAMS = sig
  val packing : GObj.widget -> unit
end

module type DRAWING = sig
  val area : GMisc.drawing_area
  (** Drawing area were the whole image is displayed. *)

  val cairo : unit -> Cairo.context
  (** Cairo context used to overlay annotation information. *)

  val pixmap : unit -> GDraw.pixmap
  (** Backing pixmap used to draw offscreen. *)

  val width : unit -> int
  (** Width of the drawing area, in pixels. *)

  val height : unit -> int
  (** Height of the drawing area, in pixels. *)

  val synchronize : unit -> unit
  (** Synchronizes the backing [pixmap] with the foreground [area]. *)
end

module Make : PARAMS -> DRAWING
(** Generator. *)
