(* CastANet - cTable.mli *)

(** Implements annotation and prediction tables. *)


(** Base tables. *)
class type ['a] table = object

    method rows : int
    (** Row count. *)

    method columns : int
    (** Column count. *)

    method level : CLevel.t
    (** Annotation level. *)
    
    method header : char list
    (** Annotation header. *)

    method get : r:int -> c:int -> 'a
    (** [get ~r ~c] returns data at row [r] and column [c].
      * @raise Invalid_argument if [r] or [c] are out of range. *)

    method set : r:int -> c:int -> 'a -> unit
    (** [set ~r ~c x] stores [x] at row [r] and column [c].
      * @raise Invalid_argument if [r] or [c] are out of range. *)

    method iter : (r:int -> c:int -> 'a -> unit) -> unit
    (** [iter f] applies function [f] in turn to all data. *)

end


(** Prediction tables. *)
class type prediction_table = object

    inherit [float list] table

    method basename : string
    (** Base name. *)
    
    method set_basename : string -> unit
    (** Edits basename. *)

    method filename
    (** Output filename. *)
   
    method to_string : string
    (** Returns the textual representation of the prediction table. *)

end


(** Annotation tables. *)
class type annotation_table = object

    inherit [CMask.layered_mask] table

    method filename : string
    (** Output filename. *)
    
    method stats : (char * int) list
    (** Returns tile count for each annotation class. *)
    
    method to_string : string
    (** Returns the textual representation of the annotation table. *)

end


val create : rows:int -> columns:int -> annotation_table list
(** [create ~rows:r ~columns:c] create an empty set of annotation tables
  * containing [r] rows and [c] columns. *)

val load : string -> annotation_table list * prediction_table list
(** [load ~zip] loads annotation and prediction tables from archive [zip]. *)

val save : zip:string -> annotation_table list -> prediction_table list -> unit
(** [save ~zip at pt] packs annotation ([at]) and prediction ([pt]) tables
  * into a single archive file [zip]. *)

