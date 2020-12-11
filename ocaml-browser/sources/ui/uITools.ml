(* The Automated Mycorrhiza Finder version 1.0 - ui/uITools.ml *)

module type PARAMS = sig
    val packing : GObj.widget -> unit
    val border_width : int
end

module type S = sig
    val toolbar : GButton.toolbar
    val erase : GButton.tool_button
    val snapshot : GButton.tool_button
end

module Make (P : PARAMS) : S = struct

    let toolbar = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:92 ~height:195
        ~packing:P.packing ()

    let packing = toolbar#insert

    let _ = UIHelper.separator packing
    let _ = UIHelper.label packing "<b><small>Toolbox</small></b>"

    let erase = 
        let btn = GButton.tool_button ~packing () in
        let box = GPack.hbox
            ~spacing:2
            ~packing:btn#set_label_widget () in
        let _ = GMisc.image 
            ~width:25
            ~pixbuf:AmfIcon.Misc.erase
            ~packing:(box#pack ~expand:false) ()
        and _ = GMisc.label
            ~markup:(UIHelper.pango_small "Eraser")
            ~xalign:0.0
            ~yalign:0.5
            ~packing:box#add () in
        btn
    
    let snapshot = 
        let btn = GButton.tool_button ~packing () in
        let box = GPack.hbox
            ~spacing:2
            ~packing:btn#set_label_widget () in
        let _ = GMisc.image 
            ~width:25
            ~pixbuf:AmfIcon.Misc.snapshot
            ~packing:(box#pack ~expand:false) ()
        and _ = GMisc.label
            ~markup:(UIHelper.pango_small "Snap")
            ~xalign:0.0
            ~yalign:0.5
            ~packing:box#add () in
        btn
end
