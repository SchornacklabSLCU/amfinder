(* CastANet Browser - imgFile.mli *)

(** File settings. *)

class type file = object
    method path : string
    (** Path to the input image. *)

    method base : string
    (** File base name. *)

    method archive : string
    (** Name of the output archive. *)
end

val create : string -> file
(** Builder. *)
