(* CastANet - cTable.mli *)

open CExt

(** Multi-level annotation tables. *)

type table
(** The type for annotation table. Annotation table consists of three matrices
  * corresponding to the different annotation levels (basic, intermediate and
  * complete). *)


(** {2 Creation and loading} *)

val create :
  ?main:CLevel.t -> 
  [ `DIM of (int * int) | `MAT of 'a Ext_Matrix.t ] -> table
(** Creates an empty matrix with either the given dimensions, or by mapping an
  * existing matrix. The optional parameter [main] allows to define the main
  * annotation layer (defaults to [`COLONIZATION]). *)

val load : string -> table option
(** Imports tables from a ZIP archive. Returns [None] in case of error. *)


(** {2 Saving and export} *)

type export_flag = [
  | `USER_ANNOT_ONLY            (** Exports user-defined annotations only. *)
  | `AUTO_BACKGROUND            (** Sets unannotated tiles as background.  *)
  | `MAIN_LEVEL_ONLY            (** Exports the main level only.           *)
  | `LEVEL of CLevel.t          (** Exports a given level.                 *)
  | `PREDICTION of string       (** Exports a given CNN prediction.        *)
  | `PRED_THRESHOLD of float    (** Prediction threshold.                  *)
  | `MIN_STDEV of float         (** Minimum dispersion value.              *)
  | `BEST_PREDICTION            (** Keep the best predicted class only.    *)
  | `EXPORT_STATISTICS          (** Exports statistics (for analysis).     *)
]
(** Table export options. These options can be combined. *)

val save : ?export:bool -> ?flags:export_flag list -> table -> string -> unit
(** Saves the given table as ZIP archive. If the optional parameter [export]
  * is set to [true], tables are produced for use with the CastANet Python
  * tools. Use [flags] to control how those tables are generated. *)


(** {2 Edition} *)

val is_valid : table -> r:int -> c:int -> bool
(** Indicates whether the given coordinates are valid. *)

val get : table -> CLevel.t -> r:int -> c:int -> CTile.t
(** [get t lvl ~r ~c] returns the annotations at row [r] and column [c] in 
  * layer [lvl] of table [t]. *)

val get_all : table -> r:int -> c:int -> (CLevel.t * CTile.t) list
(** Same as get, but gives information for all the annotation layers. *)

val add :
  table -> 
  CLevel.t -> r:int -> c:int -> char -> (CLevel.t * CTile.t) list
(** [add t x ~r ~c chr] adds annotation [chr] at row [r] and column [c] in
  * level [x]-matrix of table [t], and returns a changelog of altered 
  * annotations in all other layers. These changes are to be reflected in the
  * user interface. The function returns [None] if no change was made. *)

val remove :
  table -> 
  CLevel.t -> r:int -> c:int -> char -> (CLevel.t * CTile.t) list
(** Same arguments as [add], but this function tries and remove a given 
  * annotation from a given tile. Again the changelog indicates the triggered 
  * modifications. *)

val is_empty : table -> CLevel.t -> r:int -> c:int -> bool
(** Indicates whether a given tile contains an annotation by looking into the
  * user and hold layers.
  * @raise Invalid_argument if the row or column number is invalid. *)

val mem : 
  table -> 
  CLevel.t -> r:int -> c:int -> [ `CHR of char | `STR of string ] -> bool
(** Indicates whether an annotation exists at the given coordinates.
  * @raise Invalid_argument if the row or column number is invalid. *)


(** {2 Misc operations} *)

val main_level : table -> CLevel.t
(** Returns the main level of the given table. *)

val statistics : table -> CLevel.t -> (char * int) list
(** [statistics t lvl] returns the counts for each structure at level [lvl]
  * in table [t]. *)

val iter : (r:int -> c:int -> CTile.t -> unit) -> table -> CLevel.t -> unit
(** Table iterator. *)
