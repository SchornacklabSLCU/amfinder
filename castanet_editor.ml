(* CastANet - castanet_editor.ml *)

let _ =
  Printexc.record_backtrace true;
  print_endline "castanet-editor version 2.0";
  CMaestro.initialize ();
  CMaestro.load ();
  GMain.main ()
