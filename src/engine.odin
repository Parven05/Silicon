package silicon

import "core:log"
import "vendor:glfw"
import gl "vendor:OpenGL"
import la "core:math/linalg"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Silicon"

SUCCESS: bool

VERTEX_PATH: string : "shaders/vert.glsl"
FRAGMENT_PATH: string : "shaders/frag.glsl"

TEXTURE_PATH_01: cstring :	"resources/textures/container.jpg"

vertices := []f32 {
 	 // positions      // colors     	// texture coords
     0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
     0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
    -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
    -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0    // top left 
}

indices := []u32 {
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
	VAO := create_VAO()
	VBO := create_VBO()
	EBO := create_EBO()

	defer delete_VAO(&VAO)
	defer delete_VBO(&VBO)
	defer delete_EBO(&EBO)

	bind_VAO(&VAO)
	bind_VBO(&VBO, vertices, gl.STATIC_DRAW)
	bind_EBO(&EBO, indices, gl.STATIC_DRAW)

	link_attrib(0, 3, 8, 0)	 // position attribute
	link_attrib(1, 2, 8, 3)	 // color attribute
	link_attrib(2, 2, 8, 6)	 // texture attribute

	// textures
	texture_01 := init_texture(gl.TEXTURE_2D, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR)
	SUCCESS = load_texture(TEXTURE_PATH_01, gl.TEXTURE_2D, gl.RGB, gl.RGB)
	if !SUCCESS {
		log.error("Failed to load texture")
	} else {
		log.info("Texture loaded successfully")
	}


	for (!window_close()) {
		time := glfw.GetTime()
		gl.ClearColor(0, 0, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		activate_texture(gl.TEXTURE0)
		bind_texture(gl.TEXTURE_2D, texture_01)

		trans := la.MATRIX4F32_IDENTITY
		trans = trans * la.matrix4_translate_f32({0.5, -0.5, 0.5})
		trans = trans * la.matrix4_rotate_f32(f32(time), {0,0,1})
		trans = trans * la.matrix4_scale_f32({0.5, 0.5, 0.5})

		use_shader(shader) 
		transform := gl.GetUniformLocation(shader.id, "transform")
		gl.UniformMatrix4fv(transform, 1, gl.FALSE, &trans[0][0])

		bind_VAO(&VAO)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

	}

}
