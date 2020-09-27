(* CastANet - cMask.ml *)

open CExt
open Scanf
open Printf



type layer = [ `USER | `HOLD | `LOCK ]

type annot = [ `CHAR of char | `TEXT of string ]



module Aux = struct

   let string_of_annot = function
        | `CHAR chr -> String.make 1 (Char.uppercase_ascii chr)
        | `TEXT str -> String.uppercase_ascii str

    let mem str = function
        | `CHAR chr -> String.contains str chr
        | `TEXT txt -> let chars = Ext_Text.explode txt in
            List.for_all (String.contains str) chars

end



class type layered_mask = object

    method get : layer -> string

    method is_empty : layer -> bool

    method mem : layer -> annot -> bool

    method set : layer -> annot -> unit

    method add : layer -> annot -> unit

    method remove : layer -> annot -> unit

    method to_string : string

end



class layered_mask = object (self)

    val masks = [|""; ""; ""|]

    method private apply f = function
        | `USER -> (fun x -> f masks.(0) x)
        | `LOCK -> (fun x -> f masks.(1) x)
        | `HOLD -> (fun x -> f masks.(2) x)

    method private alter f = function
        | `USER -> (fun x -> masks.(0) <- f masks.(0) x)
        | `LOCK -> (fun x -> masks.(1) <- f masks.(1) x)
        | `HOLD -> (fun x -> masks.(2) <- f masks.(2) x)

    method get elt = self#apply (fun m _ -> m) elt ()

    method is_empty elt = self#apply (fun m _ -> m = "") elt ()

    method mem = self#apply Aux.mem

    method set = self#alter (fun _ -> Aux.string_of_annot)

    method add = 
        let union m x =
            let s = Aux.string_of_annot x in
            Ext_StringSet.union m s 
        in self#alter union

    method remove =
        let diff m x =
            let s = Aux.string_of_annot x in
            Ext_StringSet.diff m s
        in self#alter diff

    method to_string = String.concat " " (Array.to_list masks) 

end



let make ?(user = `TEXT "") ?(lock = `TEXT "") ?(hold = `TEXT "") () =
    let masks = new layered_mask in
    masks#set `USER user;
    masks#set `LOCK lock;
    masks#set `HOLD hold;
    masks



let from_string str =
    let raw = Array.of_list (String.split_on_char ' ') in
    if Array.length raw = 3 then
        let user = `TEXT raw.(0)
        and lock = `TEXT raw.(1)
        and hold = `TEXT raw.(2) in make ~user ~lock ~hold ()
    else invalid_arg "(CMask.from_string) Wrong string format"
