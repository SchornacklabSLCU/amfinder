(* CastANet - cImage.mli *) 

open CExt

(** System settings. *)
class type sys = object

    method path : string
    (** Path to the image. *)
   
    method archive : string
    (** Name of the output archive. *)
end


(** Graphical settings. *)
class type visual = object

    method rows : int
    (** Row count. *)
    
    method columns : int
    (** Column count. *)
    
    method width : int
    (** Image width, in pixels. *)

    method height : int
    (** Image height, in pixels. *)

    method ratio : int
    (** Reduction factor. *)

    method x_origin : int
    (** X-axis position to center image horizontally, in pixels. *)
    
    method y_origin : int
    (** Y-axis position to center image vertically, in pixels. *)
end


(** Tile matrices. *)
class type tile_matrix = object

    method edge : int
    (** Tile edge, in pixels. *)
    
    method contents : GdkPixbuf.pixbuf Ext_Matrix.t
    (** Tile matrix. *)

end


(** Images. *)
class type image = object

    method sys : sys
    (** File settings. *)
    
    method visual : visual
    (** Graphical settings. *)

    method small_tiles : Mosaic.tile_matrix
    (** Small tiles to be used in the rightmost UI pane. *)

    method large_tiles : Mosaic.tile_matrix
    (** Large tiles to be used in the leftmost UI pane. *)
  
    method annotations : CTable.annotation_table list
    (** Annotations. *)

    method predictions : CTable.prediction_table list
    (** Predictions. *)

end


val load : edge:int -> string -> image
(** [load ~edge:n img] loads image [img], using squares of [n]x[n] pixels 
  * as tiles.
  * @raise Invalid_argument if the file does not exist. *)


