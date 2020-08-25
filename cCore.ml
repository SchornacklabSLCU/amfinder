(* CastANet - cCore.ml *)

type icon_size = [ `SMALL | `LARGE ]

type icon_style = [ `GREY | `RGBA ]

type annotation_type = [ `COLONIZATION | `ARB_VESICLES | `ALL_FEATURES ]

let available_annotation_types = [ `COLONIZATION; `ARB_VESICLES; `ALL_FEATURES ]

let edge = 180

let data_dir = "data"

let icon_dir = Filename.concat data_dir "icons"
