package silicon

import "core:log"
import "vendor:glfw"
import gl "vendor:OpenGL"
import ma "core:math"
import la "core:math/linalg"

WINDOW_TITLE :: "Silicon"
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

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

shader : Shader
cam : Camera
projection: Projection
cube_transform: Transform

delta_time := 0.0
last_frame := 0.0

yaw : f32 = -90.0
pitch : f32 = 0.0
last_x := f32(WINDOW_WIDTH) / 2.0
last_y := f32(WINDOW_HEIGHT) / 2.0
first_mouse := true

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

	w, h := glfw.GetWindowSize(window)

	enable_feature(gl.DEPTH_TEST)
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	// shader
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

	defer delete_VAO(&VAO)
	defer delete_VBO(&VBO)

	bind_VAO(&VAO)
	bind_VBO(&VBO, vertices, gl.STATIC_DRAW)

	stride : i32 = 8
	link_attrib(0, 3, stride, 0)	 // position attribute
	link_attrib(1, 3, stride, 3)	 // color attribute
	link_attrib(2, 2, stride, 6)	 // texture attribute

	// textures
	texture_01 := init_texture(gl.TEXTURE_2D, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR)
	SUCCESS = load_texture(TEXTURE_PATH_01, gl.TEXTURE_2D, gl.RGB, gl.RGB)
	if !SUCCESS {
		log.error("Failed to load texture")
	} else {
		log.info("Texture loaded successfully")
	}

	use_shader(shader)
	init_camera(&cam, &projection)
	projection.aspect_ratio = {f32(w), f32(h)}
	camera_mode:= get_camera_mode(.PERSPECTIVE, &p)
	set_uniform(shader, "projection", &camera_mode)

	for (!window_close()) {

		current_frame := glfw.GetTime()
		delta_time = current_frame - last_frame
		last_frame = current_frame

		clear_window()
		process_input(window, &cam)

		activate_texture(gl.TEXTURE0)
		bind_texture(gl.TEXTURE_2D, texture_01)

		use_shader(shader)

		camera_view := get_camera_move_view(&cam)
		set_uniform(shader, "view", &camera_view)

		bind_VAO(&VAO)
		for i in 0..<10 {
			init_transform(&cube_transform)
			angle := 20.0 * i
			move(cube_positions[i], &cube_transform)
			rotate(f32(angle), {1.0, 0.3, 0.5}, &cube_transform)
			apply_transform(shader, &cube_transform)

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}
	}
}

mouse_callback :: proc(window: glfw.WindowHandle, x_pos: f32, y_pos: f32) {
	if (first_mouse) {
		last_x = f32(x_pos)
		last_y = f32(y_pos)
	}

	x_offset := x_pos - last_x
	y_offset := y_pos - last_y
	last_x = f32(x_pos)
	last_y = f32(y_pos)

	sensitivity : f32 = 0.1
	x_offset += sensitivity
	y_offset += sensitivity

	yaw += x_offset
	pitch += y_offset

}

clear_window :: proc() {
	gl.ClearColor(0, 0, 0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

enable_feature :: proc(cap: u32)  {
	gl.Enable(cap)
}
