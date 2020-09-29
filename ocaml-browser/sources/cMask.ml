(* CastANet - cMask.ml *)

open Morelib



class type prediction_mask = object

    method get : char -> float
    
    method mem : char -> bool
    
    method set : char -> float -> unit

    method top : (char * float) option
    
    method threshold : th:float -> (char * float) list
    
    method to_list : (char * float) list

    method of_list : (char * float) list -> unit

end



type layer = [ `USER | `HOLD | `LOCK ]

type annot = [ `CHAR of char | `TEXT of string ]



class type layered_mask = object

    method get : layer -> string

    method all : string

    method is_empty : layer -> bool

    method mem : layer -> annot -> bool

    method set : layer -> annot -> unit

    method add : layer -> annot -> unit

    method remove : layer -> annot -> unit

    method to_string : string

    method predictions : prediction_mask

end



module Aux = struct

   let string_of_annot = function
        | `CHAR chr -> String.make 1 (Char.uppercase_ascii chr)
        | `TEXT str -> String.uppercase_ascii str

    let mem str = function
        | `CHAR chr -> String.contains str chr
        | `TEXT txt -> let chars = Text.explode txt in
            List.for_all (String.contains str) chars

end



class prediction = object (self)

    val mutable predictions = []
    
    method get key =
        let key = Char.uppercase_ascii key in
        match List.assoc_opt key predictions with
        | None -> 0.0
        | Some x -> x

    method mem key =
        let key = Char.uppercase_ascii key in
        List.assoc_opt key predictions <> None

    method set key x =
        let key = Char.uppercase_ascii key in
        match self#get key with
        | 0.0 -> predictions <- (key, x) :: predictions
        |  y  -> if x <> y then 
            predictions <- (key, x) :: List.remove_assoc key predictions
   
    method top =
        match predictions with
        | [] -> None
        | hdr :: rem -> let max x y = if snd y > snd x then y else x in
            Some (List.fold_left max hdr rem)

    method threshold ~th =
        if th >= 0.0 && th <= 1.0 then
            List.filter (fun t -> snd t >= th) predictions
        else invalid_arg "(CMask.prediction_mask#threshold) Invalid threshold"

    method to_list = predictions

    method of_list t =
        let curated = List.map (fun (chr, x) ->
            if x >= 0.0 && x <= 1.0 then (Char.uppercase_ascii chr, x)
            else invalid_arg "(CMask.prediction_mask#from_list) Invalid value"
        ) t in predictions <- curated

end



class layered = object (self)

    val masks = [|""; ""; ""|]
    val predictions = new prediction

    method private apply : 'a 'b. (string -> 'a -> 'b) -> layer -> 'a -> 'b 
        = fun f layer x -> 
            match layer with
            | `USER -> f masks.(0) x
            | `LOCK -> f masks.(1) x
            | `HOLD -> f masks.(2) x

    method private alter : 'a. (string -> 'a -> string) -> layer -> 'a -> unit
        = fun f layer x ->
            match layer with
            | `USER -> masks.(0) <- f masks.(0) x
            | `LOCK -> masks.(1) <- f masks.(1) x
            | `HOLD -> masks.(2) <- f masks.(2) x

    method get elt = self#apply (fun m _ -> m) elt ""

    method all = StringSet.union (self#get `USER) (self#get `HOLD)

    method is_empty elt = self#apply (fun m _ -> m = "") elt true

    method mem x (y : annot) = self#apply Aux.mem x y

    method set x (y : annot) = self#alter (fun _ -> Aux.string_of_annot) x y

    method add layer = 
        let union m (x : annot) =
            let s = Aux.string_of_annot x in
            StringSet.union m s 
        in self#alter union layer

    method remove layer =
        let diff m (x : annot) =
            let s = Aux.string_of_annot x in
            StringSet.diff m s
        in self#alter diff layer

    method to_string = String.concat " " (Array.to_list masks) 

    method predictions = predictions

end



let make ?(user = `TEXT "") ?(lock = `TEXT "") ?(hold = `TEXT "") () =
    let masks = new layered in
    masks#set `USER user;
    masks#set `LOCK lock;
    masks#set `HOLD hold;
    masks



let of_string str =
    let raw = Array.of_list (String.split_on_char ' ' str) in
    if Array.length raw = 3 then
        let user = `TEXT raw.(0)
        and lock = `TEXT raw.(1)
        and hold = `TEXT raw.(2) in make ~user ~lock ~hold ()
    else invalid_arg "(CMask.from_string) Wrong string format"
