(* CastANet - cAction.ml *)

let may_unload_old_image () =
  let init = ref true in
  Gaux.may (fun old ->
    CImage.Binary.save_at_exit old;
    let tsv = CImage.path old
      |> Filename.remove_extension
      |> Printf.sprintf "%s.tsv" in
    CAnnot.export tsv (CImage.annotations old);
    CGUI.window#misc#hide ();
    CSettings.erase_image ();
    CDraw.unset_current ();
    CExt.Memoize.forget ();
    init := false;
  ) (CDraw.curr_image ());
  !init

let load_image toggles =
  let init = may_unload_old_image () in
  CSettings.initialize ~cmdline:init ();
  CGUI.window#show ();
  let img = CDraw.load_image () in
  CGUI.status#set_label (CImage.digest img);
  CDraw.active_layer ();
  CDraw.GUI.magnified_view ();
  CDraw.GUI.statistics ();
  CDraw.GUI.update_active_toggles toggles
