(* amf - amfAnnot.mli *)


class type annot = object

    method get : string

    method level : AmfLevel.t

    method add : char -> unit

    method set : char -> unit

    method remove : char -> unit

    method mem : char -> bool

    method off : char -> bool
    
    method has_annot : bool
    
    method is_empty : bool

end


val create : AmfLevel.t -> annot

val of_string : AmfLevel.t -> string -> annot 
