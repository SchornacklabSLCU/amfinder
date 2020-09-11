(* CastANet - uI_FileChooser.ml *)

module type PARAMS = sig
  val parent : GWindow.window
  val title : string
  val border_width : int
end

module type S = sig
  val jpeg : GFile.filter
  val tiff : GFile.filter
  val run : unit -> string
end

module Make (P : PARAMS) : S = struct
  let jpeg = GFile.filter ~name:"JPEG image" ~mime_types:["image/jpeg"] ()
  let tiff = GFile.filter ~name:"TIFF image" ~mime_types:["image/tiff"] ()

  (* The first element of wnd#action_area is the `OPEN button (see below). *)
  let set_sensitive wnd = (List.hd wnd#action_area#children)#misc#set_sensitive 

  let dialog = 
    let wnd = GWindow.file_chooser_dialog
      ~parent:P.parent
      ~destroy_with_parent:true
      ~action:`OPEN
      ~title:P.title
      ~modal:true
      ~position:`CENTER
      ~resizable:false
      ~border_width:P.border_width
      ~show:false () in
    wnd#add_button_stock `QUIT `QUIT;
    (List.hd wnd#action_area#children)#misc#modify_text [`NORMAL, `NAME "red"];
    wnd#add_select_button_stock `OPEN `OPEN;
    set_sensitive wnd false;
    wnd#connect#selection_changed (fun () ->
      Gaux.may (fun p ->
        set_sensitive wnd Sys.(file_exists p && not (is_directory p))
      ) wnd#filename
    );
    (* Other commands do not seem to affect window size. *)
    wnd#vbox#misc#set_size_request ~width:640 ~height:480 ();
    List.iter wnd#add_filter [jpeg; tiff];
    wnd#set_filter jpeg;
    wnd

  let run () =
    if dialog#run () = `OPEN then (
      dialog#misc#hide ();
      (* Should not raise an error.
       * The open button is not active when no file is selected. *)
      Option.get dialog#filename
    ) else exit 0
end
