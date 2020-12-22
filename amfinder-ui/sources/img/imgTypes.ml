(* The Automated Mycorrhiza Finder version 1.0 - img/imgTypes.ml *)

open Morelib

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
    method save_settings : Zip.out_file -> unit
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
    method empty : ?sync:bool -> r:int -> c:int -> unit -> unit
    method surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
    method locked_tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    method annotation : ?sync:bool -> r:int -> c:int -> AmfLevel.level -> CSet.t -> unit
    method annotation_other_layer : ?sync:bool -> r:int -> c:int -> unit -> unit
    method prediction : ?sync:bool -> r:int -> c:int -> float list -> char -> unit
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
    method update_cursor_pos : r:int -> c:int -> bool
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
    method get : r:int -> c:int -> unit -> AmfAnnot.annot
    method iter : (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    method iter_layer : char -> (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    method statistics : ?level:AmfLevel.level -> unit -> (char * int) list
    method has_annot : ?level:AmfLevel.level -> r:int -> c:int -> unit -> bool
    method dump : Zip.out_file -> unit
end


class type predictions = object
    method ids : AmfLevel.level -> string list
    method current : string option
    method set_current : string option -> unit
    method active : bool
    method count : int
    method next_uncertain : (int * int) option
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
    method tile : ?sync:bool -> r:int -> c:int -> unit -> bool
    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    method overlay : ?sync:bool -> r:int -> c:int -> unit -> unit
end


class type ui = object
    method set_paint : (unit -> unit) -> unit
    method update_toggles : unit -> unit
    method key_press : GdkEvent.Key.t -> bool
    method mouse_click : GdkEvent.Button.t -> bool
    method toggle : GButton.toggle_button -> char -> GdkEvent.Button.t -> bool
end
