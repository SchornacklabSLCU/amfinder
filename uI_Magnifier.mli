(* CastANet - uI_Magnifier.mli *)

module type PARAMS = sig
  val rows : int
  val columns : int
  val tile_edge : int
  val packing : GObj.widget -> unit
end

module type S = sig
  val tiles : GMisc.image array array
  (** Tiles (3 x 3 matrix) for magnified view of the cursor area. The 
    * annotations shown in [HToolbox] correspond to the central tile. *)
end

module Make : PARAMS -> S
(** Generator. *)
