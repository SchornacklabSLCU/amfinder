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


(** Multi-layered annotation mask. *)
class type layered_mask = object

    method get : layer -> string
    (** [get t] returns the active annotations of layer [t]. *)

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
end


val make : ?user:annot -> ?lock:annot -> ?hold:annot -> unit -> layered_mask
(** Create a multi-layered mask initialized with the given annotations. *)


val from_string : string -> layered_mask
(** Create a multi-layered mask from the given string. The string must consist
    of three space-separated character sets corresponding to the user, lock and
    hold annotation layers, respectively (e.g. ["AEI X R"] is a valid input).
    @raise Invalid_argument if the input string has a different format. *)


