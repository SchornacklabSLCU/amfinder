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
    AmfCallback.Magnifier.capture_screenshot Par.image;
    AmfCallback.Predictions.update_list Par.image;
    AmfCallback.Predictions.select_list_item Par.image



(*let initialize () =

  (* Callback functions for keyboard events. *)
  let connect = AmfUI.window#event#connect in
  ignore (connect#key_press Img_Trigger.arrow_keys);
  ignore (connect#key_press (fun x -> Img_Trigger.annotation_keys (`GDK x)));
  (* Callback functions for mouse events. *)
  let connect = AmfUI.Drawing.area#event#connect in
  ignore (connect#button_press Img_Trigger.mouse_click);
  ignore (connect#motion_notify Img_Trigger.mouse_move);
  ignore (connect#leave_notify Img_Trigger.mouse_leave);
  (* Repaints the tiles when the active layer changes. *)
  AmfUI.Layers.set_callback (fun _ r _ _ -> 
    if r#get_active then CPaint.active_layer ());
  (* Repaints the tiles when the annotation level changes. *)
  AmfUI.Levels.set_callback (fun _ r ->
    if r#active then CPaint.active_layer ())
*)

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
    (* Connect GtkWindow events. *)
    let connect = AmfUI.window#event#connect in
    let id = connect#key_press ~callback:image#cursor#key_press in
    image#at_exit (fun () -> GtkSignal.disconnect AmfUI.window#as_widget id);
    (* Connect GtkDrawingArea events. *)
    let connect = AmfUI.Drawing.area#event#connect in
    let id = connect#button_press ~callback:image#cursor#mouse_click in
    image#at_exit (fun () -> GtkSignal.disconnect AmfUI.Drawing.area#as_widget id);
    let id = connect#motion_notify ~callback:image#pointer#track in
    image#at_exit (fun () -> GtkSignal.disconnect AmfUI.Drawing.area#as_widget id);
    let id = connect#leave_notify ~callback:image#pointer#leave in
    image#at_exit (fun () -> GtkSignal.disconnect AmfUI.Drawing.area#as_widget id);
    (* Sets as main image. *)       
    Par.image := Some image;
    image#show ();
    AmfUI.Layers.set_callback (fun _ radio _ _ -> 
        if radio#get_active then
            image#mosaic ~sync:true ()
    );
    (* Displays cursor and the corresponding magnified view. *)
    AmfUI.status#set_label (digest image)


let main () =
    print_endline "castanet-browser 2.0";
    Printexc.record_backtrace true;
    connect_callbacks ();
    load_image ();
    GMain.main ()

let _ = main ()
