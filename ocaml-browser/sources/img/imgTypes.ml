(* amf - imgTypes.ml *)

class type file = object
    method path : string
    method base : string
    method archive : string
end


class type source = object
    method width : int
    method height : int
    method edge : int
    method rows : int
    method columns : int
end


class type brush = object
    method edge : int
    method x_origin : int
    method y_origin : int
    method make_visible : r:int -> c:int -> unit -> bool
    method r_range : int * int
    method c_range : int * int
    method backcolor : string
    method set_backcolor : string -> unit
    method background : ?sync:bool -> unit -> unit
    method pixbuf : ?sync:bool -> r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    method surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
    method missing_tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    method pointer : ?sync:bool -> r:int -> c:int -> unit -> unit
    method annotation : ?sync:bool -> r:int -> c:int -> AmfLevel.t -> char -> unit
    method prediction : ?sync:bool -> r:int -> c:int -> char -> float -> unit
    method pie_chart : ?sync:bool -> r:int -> c:int -> float list -> unit
    method prediction_palette : ?sync:bool -> unit -> unit
    method annotation_legend : ?sync:bool -> unit -> unit
    method show_probability : ?sync:bool -> float -> unit
    method hide_probability : ?sync:bool -> unit -> unit
    method sync : string -> unit -> unit
end


class type cursor = object
    method get : int * int
    method at : r:int -> c:int -> bool
    method key_press : GdkEvent.Key.t -> bool
    method mouse_click : GdkEvent.Button.t -> bool
    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
end


class type pointer = object
    method get : (int * int) option
    method at : r:int -> c:int -> bool
    method track : GdkEvent.Motion.t -> bool
    method leave : GdkEvent.Crossing.t -> bool
    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
end


class type tile_matrix = object
    method get : r:int -> c:int -> GdkPixbuf.pixbuf option
    method iter : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> unit
end


class type annotations = object
    method current_level : AmfLevel.t
    method current_layer : char
    method get : ?level:AmfLevel.t -> r:int -> c:int -> unit -> AmfAnnot.annot
    method iter : AmfLevel.t -> (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    method iter_layer : AmfLevel.t -> char -> (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    method statistics : AmfLevel.t -> (char * int) list
    method has_annot : ?level:AmfLevel.t -> r:int -> c:int -> unit -> bool
    method dump : Zip.out_file -> unit
end


class type predictions = object
    method ids : AmfLevel.t -> string list
    method current : string option
    method set_current : string option -> unit
    method active : bool
    method get : r:int -> c:int -> float list option
    method max_layer : r:int -> c:int -> (char * float) option
    method iter : 
        [ `ALL of (r:int -> c:int -> float list -> unit)
        | `MAX of (r:int -> c:int -> char * float -> unit) ] -> unit
    method iter_layer : char -> (r:int -> c:int -> float -> unit) -> unit
    method statistics : (char * int) list
    method to_string : unit -> string
    method exists : r:int -> c:int -> bool
    method dump : Zip.out_file -> unit
end


class type activations = object
    method active : bool
    method get : string -> char -> r:int -> c:int -> GdkPixbuf.pixbuf option
    method dump : Zip.out_file -> unit
end


class type draw = object
    method set_update: (unit -> unit) -> unit
    method tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    method pointer : ?sync:bool -> r:int -> c:int -> unit -> unit
    method overlay : ?sync:bool -> r:int -> c:int -> unit -> unit
end


class type ui = object
    method update : unit -> unit
    method key_press : GdkEvent.Key.t -> bool
    method mouse_click : GdkEvent.Button.t -> bool
    method toggle : GButton.toggle_button -> char -> GdkEvent.Button.t -> bool
end
