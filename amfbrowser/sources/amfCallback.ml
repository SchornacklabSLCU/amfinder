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


type image_ref = AmfImage.image option ref

let may f imgr () =
    match !imgr with
    | None -> ()
    | Some img -> f img


module Magnifier = struct

    let capture_screenshot imgr =
        let callback _ =
            may (fun image -> image#screenshot ()) imgr ();
            false
        and center = AmfUI.Magnifier.event_boxes.(1).(1) in 
        ignore (center#event#connect#button_press ~callback)

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

    let cursor imgr =
        let callback x =
            match !imgr with
            | None -> false
            | Some img -> img#cursor#key_press x 
        in ignore (AmfUI.window#event#connect#key_press ~callback)

    let annotate imgr =
        let callback x =
            match !imgr with
             | None -> false
             | Some img -> img#ui#key_press x
        in ignore (AmfUI.window#event#connect#key_press ~callback)

    let save imgr =
        let callback _ =
            Option.iter (fun image -> image#save ()) !imgr;
            false
        in ignore (AmfUI.window#event#connect#delete ~callback)
        
end


module DrawingArea = struct

    let widget = AmfUI.Drawing.area#as_widget

    let cursor imgr =
        let callback x =
            match !imgr with
            | None -> false
            | Some img -> img#cursor#mouse_click x
        in ignore (AmfUI.Drawing.area#event#connect#button_press ~callback)

    let annotate imgr =
        let callback x =
            match !imgr with
            | None -> false
            | Some img -> img#ui#mouse_click x
        in ignore (AmfUI.Drawing.area#event#connect#button_press ~callback)

    let repaint imgr =
        let may_repaint _ radio _ _ =
            if radio#get_active then
                match !imgr with
                | None -> ()
                | Some img -> img#mosaic ?sync:(Some true) ()
        in AmfUI.Layers.set_callback may_repaint

    let repaint_and_count imgr =
        let may_repaint_and_count _ radio =
            if radio#active then
                match !imgr with
                | None -> ()
                | Some img -> img#mosaic ?sync:(Some true) ();
                    img#update_statistics ()
        in AmfUI.Levels.set_callback may_repaint_and_count

end


module ToggleBar = struct

    let annotate imgr =
        AmfUI.Toggles.iter_all (fun _ chr tog ico ->
            let callback x =
                match !imgr with
                | None -> false
                | Some img -> img#ui#toggle tog ico chr x          
            in
            ignore (tog#event#connect#button_press ~callback)
        )

end



module Toolbox = struct

    open Printf

    let snap imgr =
        let snap (img : AmfImage.image) =
            (* Size of the overview window. *)
            let width, height = AmfUI.Drawing.(width (), height ()) in
            let dest = GdkPixbuf.create ~width ~height () in
            (* Retrieve current drawing *)
            let pixmap = AmfUI.Drawing.pixmap () in
            GdkPixbuf.get_from_drawable ~dest pixmap#pixmap;
            (* Generate filename *)
            let r = fst img#brush#r_range and c = fst img#brush#c_range in
            let base = Filename.remove_extension img#file#base in
            let level = AmfLevel.to_string (AmfUI.Levels.current ()) in
            let layer = match AmfUI.Layers.current () with
                | '*' -> "Overlay"
                | chr -> String.make 1 chr in
            let filename = sprintf "Snapshot_%s_%s_%s_R%d_C%d.png"
                base level layer r c in
            (* Save snapshot. *)
            GdkPixbuf.save ~filename ~typ:"png" ~options:[] dest
        in
        let callback = may snap imgr in
        ignore (AmfUI.Tools.snap#connect#clicked ~callback)

    let export imgr =
        let copy (img : AmfImage.image) =
            let level = AmfUI.Levels.current ()
            and to_string = sprintf "%s\n%c\t%s\t%d" in
            let symbols = AmfLevel.symbols level in
            img#annotations#statistics ~level ()
            |> List.fold_left2 (fun r s (c, n) -> to_string r c s n) "" symbols
            |> sprintf "Class\tDescription\tCount%s"
            |> GMain.clipboard#set_text
        in
        let callback = may copy imgr in
        ignore (AmfUI.Tools.export#connect#clicked ~callback)

end
