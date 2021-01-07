(* AMFinder - img/imgPredictions.ml
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

open Printf
open Morelib

class type cls = object
    method ids : AmfLevel.level -> string list
    method current : string option
    method current_level : AmfLevel.level option
    method set_current : string option -> unit
    method active : bool
    method count : int
    method next_uncertain : (int * int) option
    method get : r:int -> c:int -> float list option
    method max_layer : r:int -> c:int -> (char * float) option
    method iter : 
        [ `ALL of (r:int -> c:int -> float list -> unit)
        | `MAX of (r:int -> c:int -> char * float -> unit) ] -> unit
    method iter_layer : char -> (r:int -> c:int -> float -> unit) -> unit
    method statistics : (char * int) list
    method to_string : unit -> string
    method exists : r:int -> c:int -> bool
    method dump : Zip.out_file -> unit
end


module Aux = struct
    let is_prediction e = Filename.dirname e.Zip.filename = "predictions" 

    let level_of_header = function
        | ["row"; "col"; "Y"; "N"; "X"] -> Some AmfLevel.col
        | ["row"; "col"; "A"; "V"; "H"; "I"] -> Some AmfLevel.myc
        | _ -> AmfLog.warning "Malformed header in prediction table"; None

    let nrows s = String.split_on_char '\n' s
    let ncols s = String.split_on_char '\t' s
    let coord s = Scanf.sscanf s "%d\t%d\t%[^\n]" (fun r c s -> ((r, c), s))
       
    let load_table ich source e =
        let nr = source#rows and nc = source#columns in
        let id = Filename.(basename (chop_extension e.Zip.filename)) in
        match nrows (String.trim (Zip.read_entry ich e)) with
        | [] -> None
        | hdr :: dat -> match level_of_header (ncols hdr) with
            | None -> None
            | Some level -> let dat = List.map coord dat in
                (* Initialize the matrix. *)
                let table = Matrix.init nr nc (fun ~r:_ ~c:_ -> None) in
                (* Populate with values. *)
                List.iter (fun ((r, c), s) ->
                    String.split_on_char '\t' s
                    |> List.map Float.of_string
                    |> (fun x -> Matrix.set table ~r ~c (Some x))            
                ) dat;
                Some (id, (level, table))

    let to_string level table =
        let buf = Buffer.create 100 in
        (* TODO: improve this! *)
        let header = AmfLevel.to_header level
            |> List.map (String.make 1)
            |> String.concat "\t" in
        bprintf buf "row\tcol\t%s\n" header;
        Matrix.iteri (fun ~r ~c opt ->
            match opt with
            | None -> ()
            | Some t ->
                List.map Float.to_string t
                |> String.concat "\t"
                |> bprintf buf "%d\t%d\t%s\n" r c
        ) table;
        Buffer.contents buf

    let mean t = List.(fold_left (+.) 0.0 t /. (float (length t)))

    let stdev t = 
        let m = mean t in
        let s = List.fold_left (fun r x -> r +. (x -. m) *. (x -. m)) 0.0 t in
        sqrt (s /. (float (List.length t)))
    
end


class predictions input = object (self)

    val mutable curr : string option = None
    val mutable sort : (int * int) array = [||]
    val mutable spos = 0

    method private sort_by_uncertainty id =
        (* Sort valyes by their standard deviation. *)
        let coords_sorted_by_sd = List.assoc id input
            |> snd
            |> Matrix.fold (fun ~r ~c res opt -> 
                match opt with
                | None -> res
                | Some t -> ((r, c), Aux.stdev t) :: res) []
            |> List.sort (fun (_, x) (_, y) -> compare x y)
            |> List.map fst
            |> Array.of_list in
        sort <- coords_sorted_by_sd;
        spos <- 0

    method next_uncertain =
        if self#active then (
            spos <- spos + 1;
            try Some (Array.get sort spos) with _ -> None
        ) else None

    method current = curr

    method set_current = function
        | None -> curr <- None; sort <- [||]
        | Some id as some -> curr <- some; self#sort_by_uncertainty id

    method active =
        match curr with
        | None -> false
        | Some str -> fst (List.assoc str input) = AmfUI.Levels.current ()

    method ids level = 
        List.filter (fun (_, (x, _)) -> x = level) input
        |> List.split
        |> fst

    method count =
        match self#current with
        | None -> 0
        | Some id -> let mat = snd (List.assoc id input) in
            let r, c = Matrix.dim mat in r * c

    method dump och =
        List.iter (fun (id, (level, matrix)) ->
            let data = Aux.to_string level matrix
            and file = sprintf "predictions/%s.tsv" id in
            Zip.add_entry data och file
        ) input

    method private current_data = Option.map (fun x -> List.assoc x input) curr
    method private current_table = Option.map (fun (_, y) -> y) self#current_data
    method current_level = Option.map (fun (x, _) -> x) self#current_data

    method get ~r ~c = 
        match self#current_table with
        | None -> None
        | Some t -> match Matrix.get_opt t ~r ~c with
            | None -> None
            | Some opt -> opt

    method exists ~r ~c = (self#get ~r ~c) <> None

    method private max level preds =
        List.fold_left2 (fun ((_, x) as z) y chr ->
            if y > x then (chr, y) else z
        ) ('0', 0.0) preds (AmfLevel.to_header level)

    method max_layer ~r ~c =
        match self#current_data with
        | None -> None
        | Some (level, table) -> match Matrix.get_opt table ~r ~c with
            | None -> None
            | Some opt -> Option.map (self#max level) opt

    method iter (typ : [ `ALL of (r:int -> c:int -> float list -> unit)
        | `MAX of (r:int -> c:int -> char * float -> unit) ]) =
        Option.iter (fun (level, table) ->
            match typ with
            | `ALL f -> Matrix.iteri (fun ~r ~c -> Option.iter (f ~r ~c)) table
            | `MAX f -> Matrix.iteri (fun ~r ~c opt ->
                Option.iter (fun t -> f ~r ~c (self#max level t)) opt) table
        ) self#current_data

    method iter_layer chr f =
        match self#current_level with
        | None -> ()
        | Some level -> let header = AmfLevel.to_header level in
            let f = (fun ~r ~c t ->
                let elt, dat = 
                    List.fold_left2 (fun ((_, x) as o) chr y ->
                        if y > x then (chr, y) else o
                    ) ('0', 0.0) header t in
                if elt = chr then f ~r ~c dat)
            in self#iter (`ALL f)

    method statistics =
        match self#current_level with
        | None -> []
        | Some level -> let header = AmfLevel.to_header level in
            let counters = List.map (fun c -> c, ref 0) header in
            let f = (fun ~r ~c t ->
                let chr, _ = 
                    List.fold_left2 (fun ((_, x) as o) chr y ->
                        if y > x then (chr, y) else o
                    ) ('0', 0.0) header t
                in incr (List.assoc chr counters))
            in self#iter (`ALL f);
            List.map (fun (c, r) -> c, !r) counters

    method to_string () = 
        match self#current_data with
        | None -> "" (* TODO: Find a better solution to this! *)
        | Some (level, table) -> Aux.to_string level table

end


let create ?zip source =
    let inputs = match zip with
        | None -> []
        | Some ich -> Zip.entries ich
            |> List.filter Aux.is_prediction
            |> List.fold_left (fun r e ->
                match Aux.load_table ich source e with
                | None -> r 
                | Some t -> t :: r) []
    in new predictions inputs
