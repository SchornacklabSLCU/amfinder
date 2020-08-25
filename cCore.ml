(* CastANet - cCore.ml *)

type size = [ `SMALL | `LARGE ]

type style = [ `GREY | `RGBA ]

type annotation_type = [ `COLONIZATION | `ARB_VESICLES | `ALL_FEATURES ]

let edge = 180

let data_dir = "data"

let icon_dir = Filename.concat data_dir "icons"
