(* CastANet - cPTable.mli *)

(** Import/export Python prediction tables. *)


class type prediction_table = object

    method level : CLevel.t
    (** Annotation level. *)
    
    method header : char list
    (** Annotation header. *)
    
    method get : r:int -> c:int -> float list
    (** [get ~r ~c] returns the predictions at row [r] and column [c].
      * @raise Invalid_argument if [r] or [c] are out of range. *)

    method iter : (r:int -> c:int -> float list -> unit) -> unit
    (** [iter f] applies function [f] in turn to all predictions. *)

    method rows : int
    (** Row count. *)
    
    method columns : int
    (** Column count. *)

    method to_string : string
    (** Returns the textual representation of the given prediction table. *)

end


val create : data:string -> prediction_table
(** Build a table from the given string. *)

