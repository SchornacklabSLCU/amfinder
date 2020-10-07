(* CastANet - cMask.mli *)

(** Multi-fielded annotations and computer-generated predictions. *)


(** Prediction mask. *)
class type prediction_mask = object

    method get : char -> float
    (** [get c] returns the probability associated with annotation [c].
      * The function is case-insensitive. *)
    
    method mem : char -> bool
    (** [mem c] indicates whether the annotation [c] exists.
      * The function is case-insensitive. *)
    
    method set : char -> float -> unit
    (** [set c] sets the probability associated with annotation [c].
      * The function is case-insensitive. *)

    method top : (char * float) option
    (** [top] returns the annotation with highest probability, if any. *)
    
    method threshold : th:float -> (char * float) list
    (** [threshold ~th] returns the annotation with probability higher than
      * the threshold value [th].
      * @raise Invalid_argument if threshold value is not in the range 0-1. *)

    method to_list : (char * float) list
    (** [to_list] returns the list of available predictions and their associated
      * probabilities. *)

    method of_list : (char * float) list -> unit
    (** [of_list t] sets predictions from the association list [t].
      * Characters (association keys) are converted to uppercase.
      * @raise Invalid_argument if a value is not in the range 0-1. *)

end


type field = [ `USER | `LOCK | `HOLD ]
(** Mask fields, defined as follows:
    - [`USER]: user-defined annotations.
    - [`LOCK]: annotations switched off by other annotations.
    - [`HOLD]: annotations switched on by other annotations. *)


type annot = [ `CHAR of char | `TEXT of string ]
(** Single ([`CHAR]) or multiple ([`TEXT]) annotations.
    Both are treated in a case-insensitive way. *)


(** Multi-fielded annotation mask. *)
class type layered_mask = object

    method get : field -> string
    (** [get t] returns the active annotations of field [t]. *)

    method all : string
    (** Same as [get], but returns the active annotations of all fields. *)

    method is_empty : ?field:field -> unit -> bool
    (** [is_empty t] indicates whether the field [t] is unannotated. *)

    method mem : field -> annot -> bool
    (** [mem t x] indicates whether annotation [x] is active at field [t]. *)

    method set : field -> annot -> unit
    (** [set t x] defines [x] as active annotations of field [t]. *)

    method add : field -> annot -> unit
    (** [add t x] adds [x] to the active annotations of field [t]. *)

    method remove : field -> annot -> unit
    (** [remove t x] removes [x] from the active annotations of field [t]. *)

    method to_string : string
    (** Return the string representation of the multi-fielded mask. *)

    method predictions : prediction_mask
    (** Return computer-generated predictions. *)

    method has_annot : bool
    (** Indicates whether the mask contains at least one annotation. *)

    method active : annot -> bool
    (** Indicates whether the given annotation is active. *)

    method locked : annot -> bool
    (** Indicates whether the given annotation is deactivated. *)

end


val make : ?user:annot -> ?lock:annot -> ?hold:annot -> unit -> layered_mask
(** Create a multi-fielded mask initialized with the given annotations. *)


val of_string : string -> layered_mask
(** Create a multi-fielded mask from the given string. The string must consist
    of three space-separated character sets corresponding to the user, lock and
    hold annotation fields, respectively (e.g. ["AEI X R"] is a valid input).
    @raise Invalid_argument if the input string has a different format. *)


