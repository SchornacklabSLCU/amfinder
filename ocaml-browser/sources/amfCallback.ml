(* The Automated Mycorrhiza Finder version 1.0 - amfCallback.ml *)

module Magnifier = struct

    let capture_screenshot image_ref =
        let callback _ =
            Option.iter (fun image -> image#screenshot ()) !image_ref;
            false
        and center = AmfUI.Magnifier.event_boxes.(1).(1) in 
        ignore (center#event#connect#button_press ~callback)

end



module Annotations = struct

    let update_mosaic image_ref =
        let callback _ radio =
            Option.iter (fun (image : AmfImage.image) ->
                if radio#active then image#mosaic ~sync:true ()
            ) !image_ref
        in AmfUI.Levels.set_callback callback

end



module Predictions = struct

    let update_list image_ref =
        let callback level radio =
            if radio#active then
                Option.iter (fun image ->
                    image#predictions#ids level
                    |> AmfUI.Predictions.set_choices
                ) !image_ref
        in AmfUI.Levels.set_callback callback

    let update_cam image_ref =
        let callback () =
            Option.iter (fun image -> image#magnified_view ()) !image_ref
        in ignore (AmfUI.Predictions.cams#connect#toggled ~callback)

    let convert image_ref =
        let callback () =
            Option.iter (fun image ->
                image#predictions_to_annotations ?erase:None ()
            ) !image_ref
        in ignore (AmfUI.Predictions.convert#connect#clicked ~callback)

    let select_list_item image_ref =
        let callback () =
            Option.iter (fun image ->
                image#show_predictions ();
                image#update_statistics ();
                (*image#ui#update ()*)
            ) !image_ref
        in ignore (AmfUI.Predictions.overlay#connect#after#clicked ~callback)

end


module Window = struct

    let widget = AmfUI.window#as_widget

    let cursor image =
        let callback = image#cursor#key_press in
        let id = AmfUI.window#event#connect#key_press ~callback in
        image#at_exit (fun () -> GtkSignal.disconnect widget id)

    let annotate image =
        let callback = image#ui#key_press in
        let id = AmfUI.window#event#connect#key_press ~callback in
        image#at_exit (fun () -> GtkSignal.disconnect widget id)

    let save image_ref =
        let callback _ =
            Option.iter (fun image -> image#save ()) !image_ref;
            false
        in ignore (AmfUI.window#event#connect#delete ~callback)
        
end


module DrawingArea = struct

    let widget = AmfUI.Drawing.area#as_widget

    let cursor image =
        let callback = image#cursor#mouse_click in
        let id = AmfUI.Drawing.area#event#connect#button_press ~callback in
        image#at_exit (fun () -> GtkSignal.disconnect widget id)
        (*
        let callback = image#pointer#track in
        let id = AmfUI.Drawing.area#event#connect#motion_notify ~callback in
        image#at_exit (fun () -> GtkSignal.disconnect widget id);
        let callback = image#pointer#leave in
        let id = AmfUI.Drawing.area#event#connect#leave_notify ~callback in
        image#at_exit (fun () -> GtkSignal.disconnect widget id)
        *)

    let annotate image =
        let callback = image#ui#mouse_click in
        let id = AmfUI.Drawing.area#event#connect#button_press ~callback in
        image#at_exit (fun () -> GtkSignal.disconnect widget id)

end


module ToggleBar = struct

    let annotate image =
        AmfUI.Toggles.iter_all (fun _ chr toggle _ ->
            let callback = image#ui#toggle toggle chr in
            let id = toggle#event#connect#button_press ~callback in
            image#at_exit (fun () -> GtkSignal.disconnect toggle#as_widget id)
        )

end
