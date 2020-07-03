(* CastANet - cAnnot.mli *)

(** Mycorrhiza annotations. *)

type t
(** The type for annotations. *)

val codes : string
(** String containing all valid annotations. Current values include:
  * - ['A'] for arbuscules,
  * - ['V'] for vesicles,
  * - ['I'] for intraradicular hyphae (IRH),
  * - ['E'] for extraradicular hyphae (ERH),
  * - ['H'] for hyphopodia,
  * - ['R'] for root,
  * - ['D'] for low-quality tiles to be discarded. *)

val requires : char -> string
(** [requires c] returns the annotations that are required together with [c]. *)

val forbids : char -> string
(** [forbids c] returns the annotations that cannot occur together with [c]. *)

val erases : char -> string
(** [erases c] returns the annotations that get removed together with [c]. *)

val code_list : char list
(** Same as [code], but given as a list for convenience. *)

val empty : unit -> t
(** Creates an empty annotation. *)

val is_empty : t -> bool
(** Returns [true] if the annotation contains no tag. *)

val exists : t -> bool
(** Returns [true] if the annotation contains at least one tag. *)

val annotation_type : unit -> [`BINARY | `GRADIENT]
(** Returns the type of annotation used in this instance of thee application. *)

val is_gradient : unit -> bool
(** Returns [true] if the file contains probabilities. *)

val add : t -> char -> unit
(** [add t c] adds tag [c] to the annotation [t]. *)

val mem : t -> char -> bool
(** [mem t c] checks whether tag [c] is part of the annotation [t]. *)

val get : t -> char -> float
(** Get the confidence associated with the given annotation. *)

val rem : t -> char -> unit
(** [rem t c] removes tag [c] from the annotation [t]. *)

val get_group : ?palette:CPalette.id -> t -> char -> int
(** Returns the group which the probability belongs. By default, returns 
  * deciles (useful when using a color gradient). *)

val get_active : t -> string
(** Return all active annotations. *)

val export : path:string -> t array array -> unit
(** Export annotations as tabulation (['\t'])-separated values (TSV). *)

val import : path:string -> t array array
(** Import annotations from a TSV file created with [export] (see above). *)
