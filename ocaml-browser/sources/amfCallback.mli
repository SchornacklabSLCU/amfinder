(* amf - amfCallback.mli  *)

(** Event manager. *)

(** Magnifier. *)
module Magnifier : sig

    val capture_screenshot : AmfImage.image option ref -> unit

end


(** Predictions. *)
module Predictions : sig

    val update_list : AmfImage.image option ref -> unit

    val select_list_item : AmfImage.image option ref -> unit

end



(** Window events. *)
module Window : sig

    val cursor : AmfImage.image -> unit
    (** Arrow keys move cursor. *)

    val annotate : AmfImage.image -> unit
    (** Letter change annotations. *)

end


module DrawingArea : sig

    val cursor : AmfImage.image -> unit

    val annotate : AmfImage.image -> unit

end


module ToggleBar : sig

    val annotate : AmfImage.image -> unit

end
