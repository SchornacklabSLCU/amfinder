(* CastANet browser - imgAnnotations.mli *)

(** Annotation manager. *)

val create : ?zip:Zip.in_file -> ImgTypes.source -> ImgTypes.annotations
(** Builder. *)

