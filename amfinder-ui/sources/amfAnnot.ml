(* AMFinder - amfAnnot.ml
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

open Morelib


class annot ?init () =

    let valid_root_segm = AmfLevel.(to_charset root_segmentation)
    and valid_ir_struct = AmfLevel.(to_charset intraradical_structures) in

object (self)

    val mutable annot =
        match init with
        | None -> CSet.empty
        | Some str -> CSet.of_seq (String.to_seq str)

    method is_empty ?(level = AmfUI.Levels.current ()) () =
        CSet.is_empty (self#get ~level ())
        
    method has_annot ?level () = not (self#is_empty ?level ())

    method get ?(level = AmfUI.Levels.current ()) () =
        CSet.inter annot begin
            match level with 
            | AmfLevel.RootSegm -> valid_root_segm
            | AmfLevel.IRStruct -> valid_ir_struct
        end

    method mem chr = CSet.mem chr annot
    
    method all = CSet.to_seq annot |> String.of_seq

    method hot ?(level = AmfUI.Levels.current ()) () =
        List.map (fun chr ->
            if self#mem chr then 1 else 0
        ) (AmfLevel.to_header level)

    method editable = AmfUI.Levels.current () = AmfLevel.RootSegm || self#mem 'Y'

    method add ?(level = AmfUI.Levels.current ()) chr =
        if chr = '*' then List.iter (self#add ~level) (AmfLevel.to_header level)   
        else if not (self#mem chr) then begin
            match level with
            | AmfLevel.RootSegm -> assert (CSet.mem chr valid_root_segm);
                annot <- CSet.singleton chr (* mutually exclusive. *)
            | AmfLevel.IRStruct -> assert (CSet.mem chr valid_ir_struct);
                annot <- CSet.add chr annot (* can be combined. *)
        end

    method remove ?level chr =
        let level = Option.value level ~default:(AmfUI.Levels.current ()) in
        if self#mem chr then begin
            match level with
            | AmfLevel.RootSegm when CSet.mem chr valid_root_segm -> 
                annot <- CSet.empty (* Also removes intraradical structures. *)
            | AmfLevel.IRStruct when CSet.mem chr valid_ir_struct ->
                annot <- CSet.remove chr annot
            | _ -> AmfLog.error ~code:Err.Annot.invalid_character
                "Invalid character %C at annotation level %s" chr
                (AmfLevel.to_string level)
        end
end


let create () = new annot ()
let of_string s = new annot ~init:s ()
