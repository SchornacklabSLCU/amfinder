(* AMFinder - amfCallback.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

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
                if radio#active then (
                    image#mosaic ~sync:true ();
                    image#update_statistics ()
                )
            ) !image_ref
        in AmfUI.Levels.set_callback callback

end



module Predictions = struct

    let update_list image_ref =
        let callback level radio =
            if radio#active then
                Option.iter (fun image ->
                    image#predictions#ids level
                    |> AmfUI.Predictions.set_choices;
                    image#ui#update_toggles ()
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
                image#show_predictions ()
            ) !image_ref
        in ignore (AmfUI.Predictions.overlay#connect#after#clicked ~callback)

    let move_to_ambiguous_tile image_ref =
        let callback () =
            Option.iter (fun image ->
                image#uncertain_tile ()
            ) !image_ref
        in ignore (AmfUI.Predictions.ambiguities#connect#after#clicked ~callback)  

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
