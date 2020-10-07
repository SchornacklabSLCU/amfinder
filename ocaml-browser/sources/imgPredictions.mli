(* CastANet browser - imgPredictions.mli *)

(** Prediction tables. *)

class type predictions = object
    method ids : CLevel.t -> string list
    (** Returns the list of predictions at the given annotation level. *)

    method current : string option
    (** Return the identifier of the active prediction table. *)

    method set_current : string option -> unit
    (** Define the active prediction table. *)

    method active : bool
    (** Tells whether predictions are being displayed. *)

    method get : r:int -> c:int -> float list option
    (** Return the probabilities at the given coordinates. *)
    
    method max_layer : r:int -> c:int -> char option
    (** Return the layer with maximum probability at the given coordinates. *)
    
    method iter : (r:int -> c:int -> float list -> unit) -> unit
    (** Iterate over all predictions. *)
    
    method iter_layer : char -> (r:int -> c:int -> float -> unit) -> unit
    (** Iterate over tiles which have their top prediction on a given layer. *)
    
    method statistics : (char * int) list
    (** Statistics, currently based on the top prediction. *)
    
    method to_string : unit -> string
    (** Return the string representation of the active prediction table. *)
    
    method exists : r:int -> c:int -> bool
    (** Indicates whether the given tile has predictions. *)
end

val create : ?zip:Zip.in_file -> ImgSource.source -> predictions
(** Builder. *)

