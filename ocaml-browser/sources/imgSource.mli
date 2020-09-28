(* CastANet Browser - imgSource.mli *)

(** Source image settings. *)

class type t = object
    method width : int
    (** Image width, in pixels. *)

    method height : int
    (** Image height, in pixels. *) 
 
    method edge : int
    (** Tile size (in pixels) used to segment the source image. *)

    method rows : int
    (** Row count. *)

    method columns : int
    (** Column count. *)

end


val create : GdkPixbuf.pixbuf -> int -> t
(** Builder. *)

