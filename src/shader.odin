package silicon

import "core:log"
import "core:strings"
import gl "vendor:OpenGL"

Shader :: struct {
	id: u32,
}

init :: proc(vertex_path, fragment_path: string) -> (Shader, bool) {

	// Read file
	program, ok := gl.load_shaders_file(vertex_path, fragment_path)
	if !ok {
		log.error("Failed to load shaders")
		return {}, false
	}
	log.info("Shaders loaded successfully")

	return Shader{id = program}, true

}

// Use the shader
use :: proc(shader: Shader) {
	gl.UseProgram(shader.id)
}

// Utility uniform functions
set_bool :: proc(shader: Shader, name: string, value: bool) {
	location := gl.GetUniformLocation(shader.id, strings.unsafe_string_to_cstring(name))
	gl.Uniform1i(location, i32(value))
}

set_int :: proc(shader: Shader, name: string, value: i32) {
	location := gl.GetUniformLocation(shader.id, strings.unsafe_string_to_cstring(name))
	gl.Uniform1i(location, value)
}

set_float :: proc(shader: Shader, name: string, value: f32) {
	location := gl.GetUniformLocation(shader.id, strings.unsafe_string_to_cstring(name))
	gl.Uniform1f(location, value)
}
