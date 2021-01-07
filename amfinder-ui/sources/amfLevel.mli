(* AMFinder - amfLevel.mli
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


(** Annotation levels. The first level corresponds to root segmentation into 
  * colonized versus non-colonized areas, and background. The second levels aims
  * to predict AM fungal structures (arbuscules, vesicles, intraradical hyphae,
  * and hyphopodia) within colonized root areas. *)

type level = bool
(** The type alias for annotation levels. Value [true] corresponds to root 
  * segmentation, while [false] is used for mycorrhizal structures. *)

val col : level
(** Root segmentation into colonized versus non-colonized areas, and 
  * background. *) 

val myc : level
(** Mycorrhizal structures (arbuscules, vesicles, hyphopodia, intraradicular
  * hyphae). *)

val all : level list
(** List of available annotation levels, sorted from lowest to highest. *)

val is_col : level -> bool
(** Indicates whether the given level is root segmentation. *)

val is_myc : level -> bool
(** Indicates whether the given level is intraradical structures. *)

val to_string : level -> string
(** [to_string t] returns the textual representation of the level [t]. *)

val of_string : string -> level
(** [of_string s] returns the level corresponding to the string [s]. *)

val to_header : level -> char list
(** [to_header t] returns the header associated with annotation level [t]. *)

val of_header : char list -> level
(** [of_header t] returns the annotation level associated with header [t]. *)

val chars : level -> Morelib.CSet.t
(** Returns the string set containing all available chars at a given level. *)

val char_index : level -> char -> int
(** Index of the given char at the given level. *)

val all_chars_list : char list
(** All available annotations. *)

val lowest : level
(** Least detailed level of mycorrhiza annotation. *)

val highest : level
(** Most detailed level of mycorrhiza annotation. *)

val others : level -> level list
(** [other t] returns the list of all annotations levels but [t]. *)

val colors : level -> string list
(** [colors t] returns the list of RGB colors to use to display annotations at
  * level [t]. *)

val tip : char -> string
(** Keyboard shortcuts for the given annotation class. *) 

val symbols : level -> string list
(** Short symbols for annotation legend. *) 

val icon_text : level -> (char * string) list
(** Short symbols for icons. *) 

(** Annotation rules. *)
module type ANNOTATION_RULES = sig

    val add_add : char -> Morelib.CSet.t
    (** Returns the annotations to add when a given annotation is added. *)

    val add_rem : char -> Morelib.CSet.t
    (** Returns the annotations to remove when a given annotation is added. *)

    val rem_add : char -> Morelib.CSet.t
    (** Returns the annotations to add when a given annotation is removed. *)

    val rem_rem : char -> Morelib.CSet.t
    (** Returns the annotations to remove when a given annotation is removed. *)

end

val rules : level -> (module ANNOTATION_RULES)
(** Returns the rules associated with a given annotation level. *)
