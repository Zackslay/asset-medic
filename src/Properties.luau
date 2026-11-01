--!strict
export type Definition = {class: string, property: string, category: string, writable: boolean}
local definitions: {Definition} = {}
local function add(class: string, category: string, properties: {string}, writable: boolean?)
  for _, property in properties do
    table.insert(definitions, {class=class, category=category, property=property, writable=writable ~= false})
  end
end
add("Sound", "Audio", {"SoundId"})
add("Animation", "Animation", {"AnimationId"})
add("MeshPart", "Mesh", {"MeshId"}, false)
add("MeshPart", "Image", {"TextureID"})
add("SpecialMesh", "Mesh", {"MeshId"})
add("SpecialMesh", "Image", {"TextureId"})
add("Decal", "Image", {"Texture"}) -- Texture inherits Decal.
add("ImageLabel", "Image", {"Image"})
add("ImageButton", "Image", {"Image"})
add("SurfaceAppearance", "Image", {"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"})
add("ParticleEmitter", "Effect", {"Texture"})
add("Beam", "Effect", {"Texture"})
add("Trail", "Effect", {"Texture"})
return table.freeze(definitions)
