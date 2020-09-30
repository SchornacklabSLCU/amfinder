(* CastANet browser - imgActivations.mli *)

class type activations = object
    method get : string -> char -> r:int -> c:int -> GdkPixbuf.pixbuf option
end

val create : ?zip:Zip.in_file -> ImgSource.source -> activations
