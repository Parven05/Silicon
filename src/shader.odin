package silicon

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

set_uniform :: proc(shader: Shader, name: cstring, value: ^matrix[4,4]f32){
	location := gl.GetUniformLocation(shader.id, name)
	gl.UniformMatrix4fv(location, 1, gl.FALSE, &value[0][0])
}
