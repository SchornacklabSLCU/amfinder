(* The Automated Mycorrhiza Finder version 1.0 - amfMemoize.ml *)

let create f =
    let tbl = ref [] in
    fun x ->
        match List.assoc_opt x !tbl with
        | None -> let res = f x in
            tbl := (x, res) :: !tbl;
            res
        | Some res -> res

let cursor = create (AmfSurface.Square.cursor "#CC0000FF")
let arrowhead = create (AmfSurface.arrowhead "#FF0000FF")
let dashed_square = create (AmfSurface.Square.dashed "#000000FF")
let locked_square = create (AmfSurface.Square.locked "#000000FF")

let palette =
    create (fun index ->
        AmfUI.Predictions.get_colors ()
        |> (fun t -> Array.get t index)
        |> (fun color -> create (AmfSurface.circle color))
    )

let make_surface level chr x =
    AmfLevel.icon_text level
    |> List.assoc_opt chr
    |> (fun symbol -> (level, chr), create (AmfSurface.Square.filled ?symbol x))

let layers =
    List.map AmfLevel.(fun x ->
        List.map2 (make_surface x) (to_header x) (colors x)
    ) AmfLevel.all_flags
    |> List.flatten

let layer level chr = List.assoc (level, chr) layers
