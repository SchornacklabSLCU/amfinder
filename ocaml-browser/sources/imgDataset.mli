(* CastANet browser - imgDataset.mli *)

(** Datasets. *)

class type ['a] dataset = object
    method get : CLevel.t -> r:int -> c:int -> 'a
    (** Returns the item at the given coordinates and annotation level. *)

    method set : CLevel.t -> r:int -> c:int -> 'a -> unit
    (** Sets the item at the given coordinates and annotation level. *)

    method iter : CLevel.t -> (r:int -> c:int -> 'a -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

end

val create :
    ImgSource.source ->
    string -> CMask.layered_mask dataset * float list dataset
(** Builder. *)
