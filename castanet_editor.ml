(* CastANet - castanet_editor.ml *)

let _ =
  Printexc.record_backtrace true;
  print_endline "castanet-editor version 1.0";
  try
    let toggles = CEvent.initialize () in
    CAction.load_image toggles;
    GMain.main ()
  with _ -> Printexc.print_backtrace stderr
