(* AMFinder - amfbrowser.ml
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

let imgr = ref None

(* Callbacks apply to the active image. It is given as
 * a reference so changes won't affect callback behavior. *)
let connect_callbacks () =
    let open AmfCallback in
    AmfLog.info_debug "Setting up GTK callbacks";
    (* GtkWindow events. *)
    Window.save imgr;
    Window.cursor imgr;
    Window.annotate imgr;
    (* Magnifier events. *)
    Magnifier.capture_screenshot imgr;
    (* Prediction events. *)
    Predictions.convert imgr;
    Predictions.update_list imgr;
    Predictions.update_cam imgr;
    Predictions.select_list_item imgr;
    Predictions.move_to_ambiguous_tile imgr;
    (* GtkToggleButtons. *)
    ToggleBar.annotate imgr;
    (* GtkDrawingArea events. *)
    DrawingArea.cursor imgr;
    DrawingArea.annotate imgr;
    DrawingArea.repaint imgr;
    DrawingArea.repaint_and_count imgr;
    (* Toolbox events. *)
    Toolbox.snap imgr;
    Toolbox.export imgr


let load_image () =
    (* Retrieve input image. *)
    let path = match !AmfPar.path with
        | None -> AmfUI.FileChooser.run ()
        | Some path -> path in
    AmfLog.info_debug "Input image: %s" path;
    (* Displays the main window and sets UI drawing parameters. *)
    AmfUI.window#show ();
    (* Loads the image based on UI drawing parameters. *)
    let image = AmfImage.create path in   
    imgr := Some image;
    image#show ()


let _ =
    print_endline "amfbrowser version 2.0";
    AmfLog.info_debug "Running in verbose mode (debugging)";
    Printexc.record_backtrace true;
    AmfPar.initialize ();
    connect_callbacks ();
    load_image ();
    GMain.main ()
