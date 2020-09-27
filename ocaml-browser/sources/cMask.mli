(* CastANet - cMask.mli *)

(** Multi-layered annotations. *)


type layer = [ `USER | `LOCK | `HOLD ]
(** Mask layers, defined as follows:
    - [`USER]: user-defined annotations.
    - [`LOCK]: annotations switched off by other annotations.
    - [`HOLD]: annotations switched on by other annotations. *)


type annot = [ `CHAR of char | `TEXT of string ]
(** Single ([`CHAR]) or multiple ([`TEXT]) annotations.
    Both are treated in a case-insensitive way. *)


class type layered_mask = object

    method get : layer -> string
    (** Return the active annotations at a given layer. *)

    method is_empty : layer -> bool
    (** Indicate whether the given layer has no annotation. *)

    method mem : layer -> annot -> bool
    (** [mem t x] indicates whether annotations [x] are active at layer [t]. *)

    method set : layer -> annot -> unit
    (** [set t x] defines [x] as active annotations of layer [t]. *)

    method add : layer -> annot -> unit
    (** [add t x] adds [x] to the active annotations of layer [t]. *)

    method remove : layer -> annot -> unit
    (** [remove t x] removes [x] from the active annotations of layer [t]. *)

    method to_string : string
    (** Return the string representation of the multi-layered mask. *)
end


val make : ?user:annot -> ?lock:annot -> ?hold:annot -> unit -> layered_mask
(** Create a multi-layered mask and initialize with the given annotations. *)


val from_string : string -> layered_mask
(** Create a multi-layered mask from the given string. String must consists of
    three space-separated character sets corresponding to user, lock and hold
    layers, respectively (e.g. ["AEI X R"] is a valid string input).
    @raise Invalid_argument if the input string has a different format. *)


