(* The Automated Mycorrhiza Finder version 1.0 - amfSurface.mli *)

(** Cairo surfaces for drawing. *)

type edge = int
type color = string

module Create : sig
    val rectangle : width:int -> height:int -> color:string -> unit -> Cairo.context * Cairo.Surface.t
    val square : edge:int -> color:string -> unit -> Cairo.context * Cairo.Surface.t
end

val parse_html_color : color -> float * float * float * float
(** Color parser. Returns red, green, blue, and alpha channels. *)


val arrowhead : color -> edge -> Cairo.Surface.t
    (** Arrowhead oriented to the top. *)

val circle : ?margin:float -> color -> edge -> Cairo.Surface.t
(** Circle. *)


(** Squares. *)
module Square : sig
    val cursor : color -> edge -> Cairo.Surface.t
    (** Square with a thick stroke. *)

    val filled : ?symbol:string -> color -> edge -> Cairo.Surface.t
    (** Rounded, filled square with a centered symbol. *)

    val dashed : color -> edge -> Cairo.Surface.t
    (** Square with a dashed stroke. *)
end



val prediction_palette : ?step:int -> color array -> edge -> Cairo.Surface.t
(** Color palette. *)

val annotation_legend : string list -> color list -> Cairo.Surface.t
(** Annotation legend. *)

val pie_chart : ?margin:float -> float list -> color list -> edge -> Cairo.Surface.t
(** Pie chart. *)

module Dir : sig
    val top : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val bottom : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val left : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val right : background:color -> foreground:color -> edge -> Cairo.Surface.t
end
