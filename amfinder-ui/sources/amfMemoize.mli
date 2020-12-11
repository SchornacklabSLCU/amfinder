(* The Automated Mycorrhiza Finder version 1.0 - amfMemoize.mli *)

(** Memoization. *)

val create : ('a -> 'b) -> 'a -> 'b
(** [create f] returns a memoized version of function [f]. *)


(** {2 Memoized Cairo functions} *)

val cursor : AmfSurface.edge -> Cairo.Surface.t
(** Square with a thick red stroke. *)

val arrowhead : AmfSurface.edge -> Cairo.Surface.t
(** Read arrowhead. *)

val dashed_square : AmfSurface.edge -> Cairo.Surface.t
(** Rounded square with a dashed stroke. *)

val locked_square : AmfSurface.edge -> Cairo.Surface.t
(** Rounded square with a lock. *)

val empty_square : AmfSurface.edge -> Cairo.Surface.t
(** Empty square. *)

val palette : int -> AmfSurface.edge -> Cairo.Surface.t
(** Circle filled with color from a given palette. *)

val layer : AmfLevel.level -> char -> AmfSurface.edge -> Cairo.Surface.t
(** Rounded square with a symbol and filled with a specific color. *)
