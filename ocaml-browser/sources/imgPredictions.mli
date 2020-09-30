(* CastANet browser - imgPredictions.mli *)

class type predictions = object
    method current : string option
    method set_current : string -> unit
    method get : r:int -> c:int -> float list option 
    method iter : (r:int -> c:int -> float list -> unit) -> unit
    method to_string : unit -> string
end

val create : ?zip:Zip.in_file -> ImgSource.source -> predictions
(** Builder. *)

