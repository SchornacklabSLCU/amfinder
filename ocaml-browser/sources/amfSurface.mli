(* amfSurface.mli *)

(** Cairo surfaces for drawing. *)

type edge = int
type color = string

module Create : sig
    val rectangle : width:int -> height:int -> color:string -> unit -> Cairo.context * Cairo.Surface.t
    val square : edge:int -> color:string -> unit -> Cairo.context * Cairo.Surface.t
end

val parse_html_color : color -> float * float * float * float
(** Color parser. Returns red, green, blue, and alpha channels. *)

val up_arrowhead : color -> edge -> Cairo.Surface.t
(** Arrowhead oriented to the top. *)

val down_arrowhead : color -> edge -> Cairo.Surface.t
(** Arrowhead oriented to the bottom. *)

val right_arrowhead : color -> edge -> Cairo.Surface.t
(** Arrowhead oriented to the right. *)

val circle : color -> edge -> Cairo.Surface.t
(** Circle. *)

val solid_square : color -> edge -> Cairo.Surface.t
(** Square filled with the given color. *)

val empty_square : ?line:float -> color -> edge -> Cairo.Surface.t
(** Empty square with the given line thickness and color. *)

val prediction_palette : ?step:int -> color array -> edge -> Cairo.Surface.t
(** Color palette. *)

val annotation_legend : string list -> color list -> Cairo.Surface.t
(** Annotation legend. *)

val pie_chart : float list -> color list -> edge -> Cairo.Surface.t
(** Pie chart. *)

module Dir : sig
    val top : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val bottom : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val left : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val right : background:color -> foreground:color -> edge -> Cairo.Surface.t
end
