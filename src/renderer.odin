package silicon

import "core:log"
import "vendor:glfw"
import gl "vendor:OpenGL"
import ma "core:math"
import la "core:math/linalg"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Silicon"

SUCCESS: bool

VERTEX_PATH: string : "shaders/vert.glsl"
FRAGMENT_PATH: string : "shaders/frag.glsl"
TEXTURE_PATH_01: cstring :	"resources/textures/container.jpg"

vertices := []f32 {
    // Positions          // Colors           // Tex Coords
    // Back Face
    -0.5, -0.5, -0.5,   1.0, 0.0, 0.0,   0.0, 0.0,
     0.5, -0.5, -0.5,   0.0, 1.0, 0.0,   1.0, 0.0,
     0.5,  0.5, -0.5,   0.0, 0.0, 1.0,   1.0, 1.0,
     0.5,  0.5, -0.5,   0.0, 0.0, 1.0,   1.0, 1.0,
    -0.5,  0.5, -0.5,   1.0, 1.0, 0.0,   0.0, 1.0,
    -0.5, -0.5, -0.5,   1.0, 0.0, 0.0,   0.0, 0.0,

    // Front Face
    -0.5, -0.5,  0.5,   1.0, 0.0, 0.0,   0.0, 0.0,
     0.5, -0.5,  0.5,   0.0, 1.0, 0.0,   1.0, 0.0,
     0.5,  0.5,  0.5,   0.0, 0.0, 1.0,   1.0, 1.0,
     0.5,  0.5,  0.5,   0.0, 0.0, 1.0,   1.0, 1.0,
    -0.5,  0.5,  0.5,   1.0, 1.0, 0.0,   0.0, 1.0,
    -0.5, -0.5,  0.5,   1.0, 0.0, 0.0,   0.0, 0.0,

    // Left Face
    -0.5,  0.5,  0.5,   1.0, 0.0, 1.0,   1.0, 0.0,
    -0.5,  0.5, -0.5,   0.0, 1.0, 1.0,   1.0, 1.0,
    -0.5, -0.5, -0.5,   1.0, 1.0, 1.0,   0.0, 1.0,
    -0.5, -0.5, -0.5,   1.0, 1.0, 1.0,   0.0, 1.0,
    -0.5, -0.5,  0.5,   1.0, 0.0, 0.0,   0.0, 0.0,
    -0.5,  0.5,  0.5,   1.0, 0.0, 1.0,   1.0, 0.0,

    // Right Face
     0.5,  0.5,  0.5,   1.0, 0.0, 1.0,   1.0, 0.0,
     0.5,  0.5, -0.5,   0.0, 1.0, 1.0,   1.0, 1.0,
     0.5, -0.5, -0.5,   1.0, 1.0, 1.0,   0.0, 1.0,
     0.5, -0.5, -0.5,   1.0, 1.0, 1.0,   0.0, 1.0,
     0.5, -0.5,  0.5,   1.0, 0.0, 0.0,   0.0, 0.0,
     0.5,  0.5,  0.5,   1.0, 0.0, 1.0,   1.0, 0.0,

    // Bottom Face
    -0.5, -0.5, -0.5,   0.5, 0.5, 0.5,   0.0, 1.0,
     0.5, -0.5, -0.5,   0.5, 0.5, 0.5,   1.0, 1.0,
     0.5, -0.5,  0.5,   0.5, 0.5, 0.5,   1.0, 0.0,
     0.5, -0.5,  0.5,   0.5, 0.5, 0.5,   1.0, 0.0,
    -0.5, -0.5,  0.5,   0.5, 0.5, 0.5,   0.0, 0.0,
    -0.5, -0.5, -0.5,   0.5, 0.5, 0.5,   0.0, 1.0,

    // Top Face
    -0.5,  0.5, -0.5,   0.8, 0.8, 0.8,   0.0, 1.0,
     0.5,  0.5, -0.5,   0.8, 0.8, 0.8,   1.0, 1.0,
     0.5,  0.5,  0.5,   0.8, 0.8, 0.8,   1.0, 0.0,
     0.5,  0.5,  0.5,   0.8, 0.8, 0.8,   1.0, 0.0,
    -0.5,  0.5,  0.5,   0.8, 0.8, 0.8,   0.0, 0.0,
    -0.5,  0.5, -0.5,   0.8, 0.8, 0.8,   0.0, 1.0,
}

cube_positions := [][3]f32 {
	{0.0,  0.0,  0.0},
	{2.0,  5.0, -15.0},
	{-1.5, -2.2, -2.5},
	{-3.8, -2.0, -12.3},
	{2.4, -0.4, -3.5},
	{-1.7,  3.0, -7.5},
	{1.3, -2.0, -2.5},
	{1.5,  2.0, -2.5},
	{1.5,  0.2, -1.5},
	{-1.3,  1.0, -1.5}
}

indices := []u32 {
	0, 1, 3,
	1, 2, 3
}

renderer_run :: proc() {
	context.logger = log.create_console_logger()

	// window
	SUCCESS = init_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !SUCCESS {
		log.error("Failed to initialize window")
	} else {
		log.info("Window initialized successfully")
	}
	defer delete_window()

	gl.Enable(gl.DEPTH_TEST)

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
	// EBO := create_EBO()

	defer delete_VAO(&VAO)
	defer delete_VBO(&VBO)
	// defer delete_EBO(&EBO)

	bind_VAO(&VAO)
	bind_VBO(&VBO, vertices, gl.STATIC_DRAW)
	// bind_EBO(&EBO, indices, gl.STATIC_DRAW)

	link_attrib(0, 3, 8, 0)	 // position attribute
	link_attrib(1, 3, 8, 3)	 // color attribute
	link_attrib(2, 2, 8, 6)	 // texture attribute

	// textures
	texture_01 := init_texture(gl.TEXTURE_2D, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR)
	SUCCESS = load_texture(TEXTURE_PATH_01, gl.TEXTURE_2D, gl.RGB, gl.RGB)
	if !SUCCESS {
		log.error("Failed to load texture")
	} else {
		log.info("Texture loaded successfully")
	}

	use_shader(shader)

	cam : Camera
	projection := set_camera_mode(.PERSPECTIVE, &cam)
	set_mat4_f(shader, "projection", &projection)

	for (!window_close()) {
		time := glfw.GetTime()
		gl.ClearColor(0, 0, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		activate_texture(gl.TEXTURE0)
		bind_texture(gl.TEXTURE_2D, texture_01)

		use_shader(shader)

		radius : f32 = 3.0
		cam.pos.x = ma.sin(f32(time)) * radius
		cam.pos.z = ma.cos(f32(time)) * radius
		cam.pos = {cam.pos.x, 0.0, cam.pos.z}
		cam.front = {0.0, 0.0, 0.0}
		cam.up = {0.0, 1.0, 0.0}

		view := init_camera(&cam)
		set_mat4_f(shader, "view", &view)

		bind_VAO(&VAO)
		for i in 0..<10 {
			model := la.MATRIX4F32_IDENTITY
			model = model * la.matrix4_translate_f32(cube_positions[i])
			angle := 20.0 * i
			model = model * la.matrix4_rotate_f32(ma.to_radians_f32(f32(angle)), {1.0, 0.3, 0.5})
			set_mat4_f(shader, "model", &model)			// model

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}
	}
}
