(* CastANet Browser - imgSource.mli *)

(** Source image settings. *)


val create : ?zip:Zip.in_file -> GdkPixbuf.pixbuf -> ImgTypes.source
(** Builder. *)

