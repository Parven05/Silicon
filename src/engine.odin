package silicon

import "core:log"
import gl "vendor:OpenGL"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Silicon"

SUCCESS: bool

VERTEX_PATH: string : "shaders/vert.glsl"
FRAGMENT_PATH: string : "shaders/frag.glsl"

TEXTURE_PATH_01: cstring :	"resources/textures/container.jpg"

vertices := [?]f32 {
 // positions          // colors           // texture coords
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    // top left 
}

indices := [?]u32 {
	0, 1, 3,
	1, 2, 3
}

engine_run :: proc() {
	context.logger = log.create_console_logger()

	// window
	SUCCESS = init_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !SUCCESS {
		log.error("Failed to initialize window")
	} else {
		log.info("Window initialized successfully")
	}
	defer delete_window()

	// shader
	shader : Shader
	shader, SUCCESS = init_shader(VERTEX_PATH, FRAGMENT_PATH)
	if !SUCCESS {
		log.error("Failed to read shader file")
		return
	} else {
		log.info("Shader file read successfully")
	}

	// buffers
	VBO, VAO, EBO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)

	defer gl.DeleteVertexArrays(1, &VAO)
	defer gl.DeleteBuffers(1, &VBO)
	defer gl.DeleteBuffers(1, &EBO)

	// bind VAO
	gl.BindVertexArray(VAO)

	// bind VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	// bind EBO
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// color attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	// texture attribute
	gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8 * size_of(f32), uintptr(6 * size_of(f32)))
	gl.EnableVertexAttribArray(2)

	// textures
	texture_01 := init_texture(gl.TEXTURE_2D, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR)
	SUCCESS = load_texture(TEXTURE_PATH_01, gl.TEXTURE_2D, gl.RGB, gl.RGB)
	if !SUCCESS {
		log.error("Failed to load texture")
	} else {
		log.info("Texture loaded successfully")
	}

	for (!window_close()) {

		gl.ClearColor(0, 0, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		use_shader(shader) 

		activate_texture(gl.TEXTURE0)
		bind_texture(gl.TEXTURE_2D, texture_01)

		gl.BindVertexArray(VAO)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

	}

}
