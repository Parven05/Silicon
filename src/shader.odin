package silicon

import "core:strings"
import gl "vendor:OpenGL"

Shader :: struct {
	id: u32,
}

init_shader :: proc(vertex_path, fragment_path: string) -> (Shader, bool) {
	// Read file
	program, ok := gl.load_shaders_file(vertex_path, fragment_path)
	if !ok {
		return {}, false
	} 
	return Shader{id = program}, true
}

use_shader :: proc(shader: Shader) {
	gl.UseProgram(shader.id)
}

// Utility uniform functions
set_bool_shader :: proc(shader: Shader, name: string, value: bool) {
	location := gl.GetUniformLocation(shader.id, strings.unsafe_string_to_cstring(name))
	gl.Uniform1i(location, i32(value))
}

set_int_shader :: proc(shader: Shader, name: string, value: i32) {
	location := gl.GetUniformLocation(shader.id, strings.unsafe_string_to_cstring(name))
	gl.Uniform1i(location, value)
}

set_float_shader :: proc(shader: Shader, name: string, value: f32) {
	location := gl.GetUniformLocation(shader.id, strings.unsafe_string_to_cstring(name))
	gl.Uniform1f(location, value)
}
