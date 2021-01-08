(* AMFinder - amfLog.ml
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


open AmfConst


let message ~action ~label format =
    let printer = "(amfbrowser) %s: " ^^ format ^^ "." in
    Printf.ksprintf action printer label


let info format = message
    ~action:print_endline
    ~label:"INFO"
    format


let info_debug format = message
    ~action:(if AmfPar.verbose () then print_endline else ignore)
    ~label:"DEBUG"
    format


let warning format = message
    ~action:prerr_endline
    ~label:"WARNING"
    format



let error ?(code = 2) format = message
    ~action:(fun msg -> prerr_endline msg; exit code)
    ~label:"ERROR"
    format


let usage () = error "%s" "amfbrowser [OPTIONS] <IMAGE>"
