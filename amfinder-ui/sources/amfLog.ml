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
    ~label:"Info"
    format


let info_debug format = message
    ~action:(if _DEBUG_ then print_endline else ignore)
    ~label:"Debug"
    format


let warning format = message
    ~action:prerr_endline
    ~label:"Warning"
    format



let error ?(code = 2) format = message
    ~action:(fun msg -> prerr_endline msg; exit code)
    ~label:"Error"
    format


let usage () = error "%s" "amfbrowser [OPTIONS] <IMAGE>"
