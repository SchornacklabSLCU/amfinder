(* The Automated Mycorrhiza Finder version 1.0 - img/imgAnnotations.mli *)

(** Annotation manager. *)

val create : ?zip:Zip.in_file -> ImgTypes.source -> ImgTypes.annotations
(** Builder. *)

