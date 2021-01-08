(* AMFinder - amfIcon.mli
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

(** Interface icons. Icons are stored as PNG files and loaded as GdkPixbuf
  * objects at startup. Some of them have two states (type [style]), while
  * others also occur in small and large sizes (type [size]).  *)

(** Icon size.  *)
type size = [
    | `SMALL (** Small icons, 24 x 24 pixels. *)
    | `LARGE (** Large icons, 48 x 48 pixels. *)
]


(** Color mode. *)
type style = [
    | `RGB      (** Color mode (with alpha channel). *)
    | `GRAY     (** Grayscale (inactive) icon. *)
]


(** Custom amfbrowser icons. *)
type id = [
    | `APP
    | `ATTACH
    | `CAM of style
    | `CONVERT
    | `DETACH
    | `EXPORT
    | `LOW_QUALITY
    | `PALETTE
    | `SETTINGS
    | `SNAP
    | `CLASS of char * size * style
]


val get : id -> GdkPixbuf.pixbuf
(** [get ico] returns the GdkPixbuf associated with icon [ico]. *)
