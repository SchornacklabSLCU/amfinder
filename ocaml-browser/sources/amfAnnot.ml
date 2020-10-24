(* amf - amfAnnot.ml *)

open Morelib

class annot ?init level =

    let valid = AmfLevel.chars level
    and rules = AmfLevel.rules level in

object (self)

    val mutable annot =
        match init with
        | None -> CSet.empty
        | Some str -> CSet.of_seq (String.to_seq str)

    method private validate chr =
        let uch = Char.uppercase_ascii chr in
        if CSet.mem uch valid then uch
        else AmfLog.error ~code:Err.invalid_argument
            "AmfAnnot.annot#validate: Invalid argument %C" chr

    method level = level

    method get = CSet.to_seq annot |> String.of_seq
    
    method mem chr = CSet.mem chr annot
    method off chr = CSet.mem chr (CSet.diff valid annot)

    method is_empty = CSet.is_empty annot
    method has_annot = not (self#is_empty)

    method set chr =
        annot <- CSet.empty;
        self#add chr

    method add chr =
        let chr = self#validate chr in
        let module Rules = (val rules : AmfLevel.ANNOTATION_RULES) in
        if not (CSet.mem chr annot) then
            annot <- CSet.diff annot (Rules.add_rem chr)
                |> CSet.union (Rules.add_add chr)
                |> CSet.add chr

    method remove chr =
        let chr = self#validate chr in
        let module Rules = (val rules : AmfLevel.ANNOTATION_RULES) in
        if CSet.mem chr annot then
            annot <- CSet.diff annot (Rules.rem_rem chr)
                |> CSet.union (Rules.rem_add chr)
                |> CSet.remove chr

end


let create x = new annot x
let of_string level init = new annot ~init level
