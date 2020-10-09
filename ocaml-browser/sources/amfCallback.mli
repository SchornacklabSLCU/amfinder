(* The Automated Mycorrhiza Finder version 2.0 - amfCallback.mli  *)

module Magnifier : sig
    val capture_screenshot : AmfImage.image option ref -> unit
end

module Predictions : sig
    val update_list : AmfImage.image option ref -> unit
    val select_list_item : AmfImage.image option ref -> unit
end
