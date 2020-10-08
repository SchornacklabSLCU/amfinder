(** amf - imgDraw.mli *)

(** High-level drawing functions. *)

(** Drawing class. *)
class type draw = object

    method tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw tile image at the given coordinates. *)    

    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw cursor at the given coordinates. *)

    method pointer : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw mouse pointer at the given coordinates. *)

    method overlay : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw annotation/prediction at the given coordinates. *)

end


val create :
    tiles:ImgTileMatrix.tile_matrix ->
    brush:ImgBrush.brush ->
    annotations:ImgAnnotations.annotations ->
    predictions:ImgPredictions.predictions -> unit -> draw
(** Builder. *)
