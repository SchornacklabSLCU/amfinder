(* CastANet - castanet_editor.ml *)

let _ =
  Printexc.record_backtrace true;
  print_endline "castanet-editor version 1.0";
  CSettings.initialize ();
  CGUI.window#show ();
  CExt.tagger_time CDraw.load (CSettings.image ());
  CEvent.initialize ();
  CDraw.GUI.magnified_view ();
  CDraw.GUI.statistics ();
  CGUI.status#set_label (CImage.digest (CDraw.curr_image ()));
  GMain.main ()
