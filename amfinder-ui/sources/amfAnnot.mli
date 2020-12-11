(* The Automated Mycorrhiza Finder version 1.0 - amfAnnot.mli *)

(** Tile annotations. *)

class type annot = object

    method is_empty : ?level:AmfLevel.level -> unit -> bool
    (** Returns [true] when the tile has no annotation. *)

    method has_annot : ?level:AmfLevel.level -> unit -> bool
    (** Indicates whether the tile has annotation. *)

    method get : ?level:AmfLevel.level -> unit -> Morelib.CSet.t
    (** Returns the annotations associated with the given level, or the
      * current level if [?level] is [None]. *)

    method add : ?level:AmfLevel.level -> char -> unit
    (** [add chr] adds [chr] to the tile annotation. Only valid when annotating
      * intraradical structures. *)

    method remove : ?level:AmfLevel.level -> char -> unit
    (** [remove chr] removes [chr] from the tile annotation. *)

    method mem : char -> bool
    (** [mem chr] returns [true] when [chr] is part of the tile annotation. *)

    method hot : ?level:AmfLevel.level -> unit -> int list
    (** Returns a one-hot vector containing tile annotations at a given level.
      * Uses current level when [?level] is [None]. *)

    method editable : bool
    (** Indicates whether the given tile annotation is editable. A tile is 
      * always editable at the root segmentation level. Otherwise, they have to
      * carry the annotation flag ['Y']. *)

end


val create : unit -> annot
(** Creates an empty annotation. *)

val of_string : string -> annot
(** Creates an annotation and initializes it with the given string. *)
