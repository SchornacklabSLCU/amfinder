(* CastANet - castanet_editor.ml *)

open Printf

let image_ref = ref None

let connect_callbacks () =
    AmfCallback.Window.save image_ref;
    (* Magnifier events. *)
    AmfCallback.Magnifier.capture_screenshot image_ref;
    (* Annotation events. *)
    AmfCallback.Annotations.update_mosaic image_ref;
    (* Prediction events. *)
    AmfCallback.Predictions.convert image_ref;
    AmfCallback.Predictions.update_list image_ref;
    AmfCallback.Predictions.update_cam image_ref;
    AmfCallback.Predictions.select_list_item image_ref;
    AmfCallback.Predictions.move_to_ambiguous_tile image_ref

let connect_image image =
    (* GtkWindow events. *)
    AmfCallback.Window.cursor image;
    AmfCallback.Window.annotate image;
    (* GtkDrawingArea events. *)
    AmfCallback.DrawingArea.cursor image;
    AmfCallback.DrawingArea.annotate image;
    (* GtkToggleButtons. *)
    AmfCallback.ToggleBar.annotate image


let load_image () =
    (* Retrieves an image path from the command line or from a file chooser. *)
    let image_path = match !AmfPar.path with
        | None -> AmfUI.FileChooser.run ()
        | Some path -> path in
    (* Displays the main window in order to retrieve drawing parameters. *)
    AmfUI.window#show ();
    (* Loads the image, creates tiles and populates the main window. *)
    let image = AmfImage.create image_path in
    (* Sets as main image. *)       
    image_ref := Some image;
    connect_image image;
    image#show ();
    AmfUI.Layers.set_callback (fun _ radio _ _ -> 
        if radio#get_active then image#mosaic ~sync:true ()
    )


let main () =
    print_endline "AMFinder interface version 2.0";
    Printexc.record_backtrace true;
    AmfPar.initialize ();
    connect_callbacks ();
    load_image ();
    GMain.main ()

let _ = main ()
