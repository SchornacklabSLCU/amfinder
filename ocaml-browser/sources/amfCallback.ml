(* The Automated Mycorrhiza Finder version 2.0 - amfCallback.ml  *)

module Magnifier = struct

    let capture_screenshot image_ref =
        let callback _ =
            Option.iter (fun image -> image#screenshot ()) !image_ref;
            false
        and center = CGUI.Magnifier.event_boxes.(1).(1) in 
        ignore (center#event#connect#button_press ~callback)

end


module Predictions = struct

    let update_list image_ref =
        CGUI.Levels.set_callback (fun level radio ->
            if radio#active then
                Option.iter (fun image ->
                    image#predictions#ids level
                    |> CGUI.Predictions.set_choices
                ) !image_ref
        )

    let select_list_item image_ref =
        CGUI.Predictions.overlay#connect#clicked (fun () ->
            Option.iter (fun image ->
                match CGUI.Predictions.get_active () with
                | None -> ()
                | Some id -> image#predictions#set_current id
            ) !image_ref
        ); ()

end
