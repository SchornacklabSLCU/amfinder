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

    let valid_col = AmfLevel.chars AmfLevel.col
    and valid_myc = AmfLevel.chars AmfLevel.myc in

object (self)

    val mutable annot =
        match init with
        | None -> CSet.empty
        | Some str -> CSet.of_seq (String.to_seq str)

    method private valid_chars level =
        if AmfLevel.is_col level then valid_col
        else valid_myc

    method is_empty ?(level = AmfUI.Levels.current ()) () =
        CSet.is_empty (self#get ~level ())
        
    method has_annot ?level () = not (self#is_empty ?level ())

    method get ?(level = AmfUI.Levels.current ()) () =
        CSet.inter annot (self#valid_chars level)

    method mem chr = CSet.mem chr annot
    
    method all = CSet.to_seq annot |> String.of_seq

    method hot ?(level = AmfUI.Levels.current ()) () =
        List.map (fun chr ->
            if self#mem chr then 1 else 0
        ) (AmfLevel.to_header level)

    method editable =
        AmfLevel.is_col (AmfUI.Levels.current ()) || self#mem 'Y'

    method erase ?(level = AmfUI.Levels.current ()) () = 
        annot <- CSet.diff annot (self#valid_chars level)

    method add ?(level = AmfUI.Levels.current ()) chr =
        if chr = '*' then List.iter (self#add ~level) (AmfLevel.to_header level)   
        else if not (self#mem chr) then begin
            match level with
            | true  -> assert (CSet.mem chr valid_col);
                annot <- CSet.singleton chr (* mutually exclusive. *)
            | false -> assert (CSet.mem chr valid_myc);
                annot <- CSet.add chr annot (* can be combined. *)
        end

    method remove ?level chr =
        let level = Option.value level ~default:(AmfUI.Levels.current ()) in
        if self#mem chr then begin
            match level with
            | true when CSet.mem chr valid_col -> 
                annot <- CSet.empty (* Also removes intraradical structures. *)
            | false when CSet.mem chr valid_myc ->
                annot <- CSet.remove chr annot
            | _ -> AmfLog.error ~code:Err.Annot.invalid_character
                "Invalid character %C at annotation level %s" chr
                (AmfLevel.to_string level)
        end
end


let create () = new annot ()
let of_string s = new annot ~init:s ()
