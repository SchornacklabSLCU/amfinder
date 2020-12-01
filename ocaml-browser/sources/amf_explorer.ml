(* CastANet - castanet_editor.ml *)

open Printf

module Par = struct
  open Arg
  let edge = ref 40
  let path = ref None
  let image = ref None
  let set_image_path x = if Sys.file_exists x then path := Some x
  let usage = "castanet_editor.exe [OPTIONS] [IMAGE_PATH]"
  let specs = align [
    "--edge", Set_int edge, sprintf " Tile size (default: %d pixels)." !edge;
  ]
  let initialize () = parse specs set_image_path usage
end



let connect_callbacks () =
    AmfCallback.Window.save Par.image;
    (* Magnifier events. *)
    AmfCallback.Magnifier.capture_screenshot Par.image;
    (* Prediction events. *)
    AmfCallback.Predictions.convert Par.image;
    AmfCallback.Predictions.update_list Par.image;
    AmfCallback.Predictions.update_cam Par.image;
    AmfCallback.Predictions.select_list_item Par.image

let connect_image image =
    (* GtkWindow events. *)
    AmfCallback.Window.cursor image;
    AmfCallback.Window.annotate image;
    (* GtkDrawingArea events. *)
    AmfCallback.DrawingArea.cursor image;
    AmfCallback.DrawingArea.annotate image;
    (* GtkToggleButtons. *)
    AmfCallback.ToggleBar.annotate image

let digest image =
  sprintf "<small><tt> \
    <b>Image:</b> %s ▪ \
    <b>Size:</b> %d × %d pixels ▪ \
    <b>Tiles:</b> %d × %d</tt></small>" 
    image#file#base
    image#source#width image#source#height
    image#source#rows image#source#columns



let load_image () =
    (* Retrieves an image path from the command line or from a file chooser. *)
    Par.initialize ();
    let image_path = match !Par.path with
        | None -> AmfUI.FileChooser.run ()
        | Some path -> path in
    (* Displays the main window in order to retrieve drawing parameters. *)
    AmfUI.window#show ();
    (* Loads the image, creates tiles and populates the main window. *)
    let image = AmfImage.create ~edge:!Par.edge image_path in
    (* Sets as main image. *)       
    Par.image := Some image;
    connect_image image;
    image#show ();
    AmfUI.Layers.set_callback (fun _ radio _ _ -> 
        if radio#get_active then image#mosaic ~sync:true ()
    );
    (* Displays general information regarding the image. *)
    AmfUI.status#set_label (digest image)


let main () =
    print_endline "castanet-browser 2.0";
    Printexc.record_backtrace true;
    connect_callbacks ();
    load_image ();
    GMain.main ()

let _ = main ()
