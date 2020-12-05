(* The Automated Mycorrhiza Finder version 1.0 - amfLog.ml *)



let message ~action ~channel ~label format =

    let printer = "(CastANet) %s: " ^^ format ^^ ".\n%!" in
    
    Printf.kfprintf action channel printer label



let info format =
  message
    ~action:ignore
    ~channel:stdout
    ~label:"Info"
    format



let warning format =
  message
    ~action:ignore
    ~channel:stderr
    ~label:"Warning"
    format



let error ?(code = 2) format =
  message
    ~action:(fun _ -> exit code)
    ~channel:stderr
    ~label:"Error"
    format



let usage () = error "%s" "castanet-editor [OPTIONS] <IMAGE>"
