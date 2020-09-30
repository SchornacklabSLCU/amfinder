(* CastANet browser - imgAnnotations.mli *)

(** Datasets. *)

class type annotations = object
    method get : CLevel.t -> r:int -> c:int -> CMask.layered_mask option
    (** Returns the item at the given coordinates and annotation level. *)

    method iter : CLevel.t -> (r:int -> c:int -> CMask.layered_mask -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method iter_layer : CLevel.t -> char -> (r:int -> c:int -> CMask.layered_mask -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method statistics : CLevel.t -> (char * int) list
    (** Returns the current statistics. *)

    method to_string : CLevel.t -> string
    (** Return the string representation of the table at the given level. *)
end

val create : ?zip:Zip.in_file -> ImgSource.source -> annotations
(** Read annotations. *)

