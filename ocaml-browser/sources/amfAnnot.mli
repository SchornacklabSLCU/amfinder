(* amf - amfAnnot.mli *)


class type annot = object

    method get : string

    method level : AmfLevel.level

    method add : char -> unit

    method set : char -> unit

    method remove : char -> unit

    method mem : char -> bool

    method hot : int list

    method off : char -> bool
    
    method has_annot : bool
    
    method is_empty : bool

end


val create : AmfLevel.level -> annot

val of_string : AmfLevel.level -> string -> annot 
