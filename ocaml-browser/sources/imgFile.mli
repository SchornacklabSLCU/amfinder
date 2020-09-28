(* CastANet Browser - imgFile.mli *)

class type t = object
    method path : string
    method archive : string
end

val create : string -> t
