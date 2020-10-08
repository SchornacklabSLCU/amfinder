(* CastANet browser - imgActivations.mli *)

(** Class activation maps (CAMs). *)

class type activations = object
    method active : bool
    (** Indicates whether class activation maps are to be displayed. *)
    
    method get : string -> char -> r:int -> c:int -> GdkPixbuf.pixbuf option
    (** Return the CAM associated with a given tile. *)
end

val create : ?zip:Zip.in_file -> ImgSource.source -> activations
(** Builder. *)
