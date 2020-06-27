(* CastANet - main.ml *)

let _ =
  Printexc.record_backtrace true;
  print_endline "castanet-editor version 1.0";
  CGUI.window#show ();
  CSettings.initialize ();
  CExt.tagger_time CDraw.load (CSettings.image ());
  CEvent.initialize ();
  CDraw.GUI.magnified_view ();
  CGUI.status#set_label (CImage.digest (CDraw.curr_image ()));
  GMain.main ()
