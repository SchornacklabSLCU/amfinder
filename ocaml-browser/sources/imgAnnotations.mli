(* CastANet browser - imgAnnotations.mli *)

(** Datasets. *)

class type annotations = object
    method current_level : CLevel.t
    (** Returns the current level. *)
    
    method current_layer : char
    (** Returns the current layer (uses ['*'] for the main layer). *)

    method get : ?level:CLevel.t -> r:int -> c:int -> unit -> CMask.layered_mask
    (** Returns the item at the given coordinates and annotation level. *)

    method iter : CLevel.t -> (r:int -> c:int -> CMask.layered_mask -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method iter_layer : CLevel.t -> char -> (r:int -> c:int -> CMask.layered_mask -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method statistics : CLevel.t -> (char * int) list
    (** Returns the current statistics. *)

    method to_string : CLevel.t -> string
    (** Return the string representation of the table at the given level. *)
    
    method has_annot : ?level:CLevel.t -> r:int -> c:int -> unit -> bool
    (** Indicates whether the given tile has annotation. By default, checks the
      * current annotation layer. *)
    
end

val create : ?zip:Zip.in_file -> ImgSource.source -> annotations
(** Read annotations. *)

