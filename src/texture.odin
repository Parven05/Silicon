package silicon

import gl "vendor:OpenGL"
import stb "vendor:stb/image"

Texture :: struct {
    id: u32,
}

@require_results
init_texture :: proc (target: u32, wrap, filter_min, filter_max: i32) -> (Texture) {
    texture: u32
    gl.GenTextures(1, &texture)
    gl.BindTexture(target, texture)

    gl.TexParameteri(target, gl.TEXTURE_WRAP_S, wrap)
    gl.TexParameteri(target, gl.TEXTURE_WRAP_T, wrap)
    gl.TexParameteri(target, gl.TEXTURE_MIN_FILTER, filter_min)
    gl.TexParameteri(target, gl.TEXTURE_MAG_FILTER, filter_max)

    return Texture{id = texture}
}

load_texture :: proc (filepath: cstring, target: u32, internal_format:i32, format:u32) -> (bool) {
    width, height, num_channel : i32
    data := stb.load(filepath, &width, &height, &num_channel, 0)

    if (data == nil) {
       return false
    } else {
        gl.TexImage2D(target, 0, internal_format, width, height, 0, format, gl.UNSIGNED_BYTE, data)
        gl.GenerateMipmap(target)

        return true
    }
     stb.image_free(data)

     return true

}

// Utility functions
activate_texture :: proc (texture: u32) {
    gl.ActiveTexture(texture)
}

bind_texture :: proc (target: u32, texture: Texture) {
    gl.BindTexture(target, texture.id)
}
