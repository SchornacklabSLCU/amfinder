(* CastANet - cMask.mli *)

(** Multi-layered annotations and computer-generated predictions. *)


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


type layer = [ `USER | `LOCK | `HOLD ]
(** Mask layers, defined as follows:
    - [`USER]: user-defined annotations.
    - [`LOCK]: annotations switched off by other annotations.
    - [`HOLD]: annotations switched on by other annotations. *)


type annot = [ `CHAR of char | `TEXT of string ]
(** Single ([`CHAR]) or multiple ([`TEXT]) annotations.
    Both are treated in a case-insensitive way. *)


(** Multi-layered annotation mask. *)
class type layered_mask = object

    method get : layer -> string
    (** [get t] returns the active annotations of layer [t]. *)

    method all : string
    (** Same as [get], but returns the active annotations of all layers. *)

    method is_empty : layer -> bool
    (** [is_empty t] indicates whether the layer [t] is unannotated. *)

    method mem : layer -> annot -> bool
    (** [mem t x] indicates whether annotation [x] is active at layer [t]. *)

    method set : layer -> annot -> unit
    (** [set t x] defines [x] as active annotations of layer [t]. *)

    method add : layer -> annot -> unit
    (** [add t x] adds [x] to the active annotations of layer [t]. *)

    method remove : layer -> annot -> unit
    (** [remove t x] removes [x] from the active annotations of layer [t]. *)

    method to_string : string
    (** Return the string representation of the multi-layered mask. *)

    method predictions : prediction_mask
    (** Return computer-generated predictions. *)

end


val make : ?user:annot -> ?lock:annot -> ?hold:annot -> unit -> layered_mask
(** Create a multi-layered mask initialized with the given annotations. *)


val of_string : string -> layered_mask
(** Create a multi-layered mask from the given string. The string must consist
    of three space-separated character sets corresponding to the user, lock and
    hold annotation layers, respectively (e.g. ["AEI X R"] is a valid input).
    @raise Invalid_argument if the input string has a different format. *)


