package silicon

import "core:log"
import gl "vendor:OpenGL"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Silicon"

vertex_path: string : "shaders/vert.glsl"
fragment_path: string : "shaders/frag.glsl"

vertices := [?]f32 {
	-0.5,
	-0.5,
	0.0,
	1.0,
	0.0,
	0.0,
	0.5,
	-0.5,
	0.0,
	0.0,
	1.0,
	0.0,
	0.0,
	0.5,
	0.0,
	0.0,
	0.0,
	1.0,
}

engine_run :: proc() {
	context.logger = log.create_console_logger()

	// window
	init_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer delete_window()

	// shader
	shader, ok := init(vertex_path, fragment_path)
	if !ok {return}

	// Buffer
	VBO, VAO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)

	// bind vertex array object
	gl.BindVertexArray(VAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 6 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// color attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 6 * size_of(f32), uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	for (!window_close()) {

		gl.ClearColor(0, 0, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		use(shader)

		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)
	}

}
