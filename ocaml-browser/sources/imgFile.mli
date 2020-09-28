(* CastANet Browser - imgFile.mli *)

(** File settings. *)

class type t = object
    method path : string
    (** Path to the input image. *)

    method archive : string
    (** Name of the output archive. *)
end

val create : string -> t
(** Builder. *)
