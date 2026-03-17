package silicon

import "core:log"
import "vendor:glfw"
import gl "vendor:OpenGL"
import la "core:math/linalg"

import im "libs:imgui"
import "libs:imgui/imgui_impl_glfw"
import "libs:imgui/imgui_impl_opengl3"

// error check
@(private="file") SUCCESS: bool

// window
@(private="file") WINDOW_TITLE :: "Silicon"
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

// shader file
@(private="file") VERTEX_PATH: string : "shaders/vert.glsl"
@(private="file") FRAGMENT_PATH: string : "shaders/frag.glsl"

// assets
@(private="file") TEXTURE_PATH_01: cstring : "assets/textures/container.jpg"

@(private="file") vertices := []f32 {
    // Positions  		// Tex Coords
    // Back Face
    -0.5, -0.5, -0.5,   0.0, 0.0,
     0.5, -0.5, -0.5,   1.0, 0.0,
     0.5,  0.5, -0.5,   1.0, 1.0,
     0.5,  0.5, -0.5,   1.0, 1.0,
    -0.5,  0.5, -0.5,   0.0, 1.0,
    -0.5, -0.5, -0.5,   0.0, 0.0,

    // Front Face
    -0.5, -0.5,  0.5,   0.0, 0.0,
     0.5, -0.5,  0.5,   1.0, 0.0,
     0.5,  0.5,  0.5,   1.0, 1.0,
     0.5,  0.5,  0.5,   1.0, 1.0,
    -0.5,  0.5,  0.5,   0.0, 1.0,
    -0.5, -0.5,  0.5,   0.0, 0.0,

    // Left Face
    -0.5,  0.5,  0.5,   1.0, 0.0,
    -0.5,  0.5, -0.5,   1.0, 1.0,
    -0.5, -0.5, -0.5,   0.0, 1.0,
    -0.5, -0.5, -0.5,   0.0, 1.0,
    -0.5, -0.5,  0.5,   0.0, 0.0,
    -0.5,  0.5,  0.5,   1.0, 0.0,

    // Right Face
     0.5,  0.5,  0.5,   1.0, 0.0,
     0.5,  0.5, -0.5,   1.0, 1.0,
     0.5, -0.5, -0.5,   0.0, 1.0,
     0.5, -0.5, -0.5,   0.0, 1.0,
     0.5, -0.5,  0.5,   0.0, 0.0,
     0.5,  0.5,  0.5,   1.0, 0.0,

    // Bottom Face
    -0.5, -0.5, -0.5,   0.0, 1.0,
     0.5, -0.5, -0.5,   1.0, 1.0,
     0.5, -0.5,  0.5,   1.0, 0.0,
     0.5, -0.5,  0.5,   1.0, 0.0,
    -0.5, -0.5,  0.5,   0.0, 0.0,
    -0.5, -0.5, -0.5,   0.0, 1.0,

    // Top Face
    -0.5,  0.5, -0.5,   0.0, 1.0,
     0.5,  0.5, -0.5,   1.0, 1.0,
     0.5,  0.5,  0.5,   1.0, 0.0,
     0.5,  0.5,  0.5,   1.0, 0.0,
    -0.5,  0.5,  0.5,   0.0, 0.0,
    -0.5,  0.5, -0.5,   0.0, 1.0,
}

@(private="file") cube_positions := [][3]f32 {
	{0.0,  0.0,  0.0},
	{2.0,  5.0, -15.0},
	{-1.5, -2.2, -2.5},
	{-3.8, -2.0, -12.3},
	{2.4, -0.4, -3.5},
	{-1.7,  3.0, -7.5},
	{1.3, -2.0, -2.5},
	{1.5,  2.0, -2.5},
	{1.5,  0.2, -1.5},
	{-1.3,  1.0, -1.5},
}

@(private="file") shader : Shader
@(private="file") camera : Camera
@(private="file") cube_transform: Transform
@(private="file") last_frame := 0.0
delta_time := 0.0

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

	glfw.SetWindowUserPointer(window, &camera)

	enable_feature(gl.DEPTH_TEST)

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, mouse_scroll_callback)

	// imgui
	im.CreateContext()
	defer im.DestroyContext()

	imgui_impl_glfw.InitForOpenGL(window, true)
	defer imgui_impl_glfw.Shutdown()
	imgui_impl_opengl3.Init("#version 460")
	defer imgui_impl_opengl3.Shutdown()

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

	stride : i32 = 5
	link_attrib(0, 3, stride, 0)	 // position attribute
	link_attrib(1, 2, stride, 3)	 // texture attribute

	// textures
	texture_01 := init_texture(gl.TEXTURE_2D, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR)
	SUCCESS = load_texture(TEXTURE_PATH_01, gl.TEXTURE_2D, gl.RGB, gl.RGB)
	if !SUCCESS {
		log.error("Failed to load texture")
	} else {
		log.info("Texture loaded successfully")
	}

	init_camera(&camera)
	camera.aspect_ratio = {f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)}

	use_shader(shader)

	for (!window_close()) {
		set_deltatime()
		clear_window()
		process_input()

		activate_texture(gl.TEXTURE0)
		bind_texture(gl.TEXTURE_2D, texture_01)

		use_shader(shader)

		camera_projection := get_camera_mode(.PERSPECTIVE, &camera)
		set_uniform(shader, "projection", &camera_projection)

		camera_view := get_camera_view(&camera)
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

		// imgui
		window_width, window_height := glfw.GetWindowSize(window)

		imgui_impl_opengl3.NewFrame()
        imgui_impl_glfw.NewFrame()
        im.NewFrame()

        bar_height : f32 = 25.0

        im.SetNextWindowPos({0, f32(window_height) - bar_height})
        im.SetNextWindowSize({f32(window_width) + 2, bar_height})

        flags := im.WindowFlags{.NoTitleBar, .NoResize, .NoMove, .NoScrollbar, .NoBackground}

  		im.Begin("Status Bar", nil, flags)
   		im.Text("Camera :")
     	im.SameLine()
     	draw_vec3_colored("Pos", camera.pos)

      	im.SameLine()
	    im.Text("|")
	    im.SameLine()
	    draw_vec3_colored("Rot", camera.rot.x)

	    im.SameLine()
	    im.Text("| FOV: %.2f", camera.fov)
        im.End()

        im.Render()

        imgui_impl_opengl3.RenderDrawData(im.GetDrawData())
	}
}


set_deltatime :: proc () {
	current_frame := glfw.GetTime()
	delta_time = current_frame - last_frame
	last_frame = current_frame
}

process_input :: proc() {
	close_window_esc(window)
	move_camera_keys(&camera)
	reset_camera_key(&camera)
}

clear_window :: proc() {
	gl.ClearColor(0.20, 0.20, 0.20, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

enable_feature :: proc(cap: u32)  {
	gl.Enable(cap)
}

draw_vec3_colored :: proc(label: string, v: [3]f32) {
    im.Text("%s: ", label)
    im.SameLine(0, 0)

    im.TextColored({1.0, 0.4, 0.4, 1.0}, "%.2f", v.x) // X - Red
    im.SameLine(0, 0)
    im.Text(", ")
    im.SameLine(0, 2)

    im.TextColored({0.4, 1.0, 0.4, 1.0}, "%.2f", v.y) // Y - Green
    im.SameLine(0, 0)
    im.Text(", ")
    im.SameLine(0, 2)

    im.TextColored({0.4, 0.4, 1.0, 1.0}, "%.2f", v.z) // Z - Blue
    im.SameLine(0, 0)
}
