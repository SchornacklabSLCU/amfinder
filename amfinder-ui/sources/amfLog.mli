(* The Automated Mycorrhiza Finder version 1.0 - amfLog.mli *)

(** Logging functions. *)

val info : ('a, out_channel, unit, unit, unit, unit) format6 -> 'a
(** Prints a piece of information to [stdout]. *)

val warning : ('a, out_channel, unit, unit, unit, unit) format6 -> 'a
(** Prints a warning message to [stderr]. *)

val error : ?code:int -> ('a, out_channel, unit, unit, unit, 'b) format6 -> 'a
(** Prints an error message to [stderr] and terminates with the given code. *)

val usage : unit -> 'a
(** Specialized [error] function with application message. *)
