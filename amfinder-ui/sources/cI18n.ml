(* CastANet - cI18n.ml *)

type sentence = [
  | `CURRENT_PALETTE

]


module Lang = struct
  let english = [
    `CURRENT_PALETTE, "Current palette:"
  ]
  let french = [
    `CURRENT_PALETTE, "Palette actuelle :"
  ]
end

let languages = [
  "english", Lang.english;
  "french", Lang.french;
]

let current = ref "english"

let set ~lang:s =
  let id = String.lowercase_ascii s in
  if List.mem_assoc id languages then current := id
  else AmfLog.warning "Unknown language %s" s

let get elt = List.assoc elt (List.assoc !current languages)
