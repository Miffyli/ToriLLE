-- unload_texture(texture id)

-- USE: Unloads the texture from memory.
-- NOTES: For use after load_texture.

texid = load_texture("example/tex1.tga")

unload_texture(texid)