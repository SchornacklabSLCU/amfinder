(* The Automated Mycorrhiza Finder version 1.0 - amfSurface.mli *)

(** Cairo surfaces for drawing. *)

type edge = int
type color = string

module Create : sig
    val rectangle : width:int -> height:int -> color:string -> unit -> Cairo.context * Cairo.Surface.t
end


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

    val colors : color list -> edge -> Cairo.Surface.t
    (** Rounded square filled with multiple colors. *)

    val dashed : color -> edge -> Cairo.Surface.t
    (** Square with a dashed stroke and an eye symbol. *)
    
    val locked : color -> edge -> Cairo.Surface.t
    (** Square with a dashed stroke and a red lock. *)

    val empty : color -> edge -> Cairo.Surface.t
    (** Rounded square with a solid stroke and a white background. *)
end



val prediction_palette : ?step:int -> color array -> edge -> Cairo.Surface.t
(** Color palette. *)

val annotation_legend : string list -> color list -> Cairo.Surface.t
(** Annotation legend. *)

val pie_chart : ?margin:float -> float list -> color list -> edge -> Cairo.Surface.t
(** Pie chart for root segmentation. *)

val radar : ?margin:float -> float list -> color list -> edge -> Cairo.Surface.t
(** Same, but for prediction of intraradical structures. *)

module Dir : sig
    val top : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val bottom : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val left : background:color -> foreground:color -> edge -> Cairo.Surface.t
    val right : background:color -> foreground:color -> edge -> Cairo.Surface.t
end
