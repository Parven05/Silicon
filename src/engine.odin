/*
This is the core of the engine. It handles the basic life of the engine
opening a window, drawing shapes on the screen, and cleaning up when done.
*/
package silicon

import "core:log"
import "vendor:glfw"
import gl "vendor:OpenGL"
import la "core:math/linalg"

@(private="file") VERTEX_PATH: string : "shaders/vert.glsl"
@(private="file") FRAGMENT_PATH: string : "shaders/frag.glsl"
@(private="file") TEXTURE_PATH_01: cstring : "assets/textures/container.jpg"

@(private="file") SUCCESS: bool
@(private="file") vbo : VBO
@(private="file") vao : VAO
@(private="file") texture_01 : Texture
@(private="file") shader : Shader
@(private="file") camera : Camera
@(private="file") cube_transform: Transform

/*
Starts the engine and keeps it running until close the window.
*/
run_engine :: proc() {
	init_engine()
	defer delete_engine()

	init_ui()
	defer delete_ui()

	for (!window_close()) {
		process_input()

		pre_render_engine()
		render_engine()

		pre_render_ui()
		draw_status_bottom_bar_ui(&camera)
		render_ui()

		post_render_engine()
	}
}

/*
Sets everything up so the engine is ready to use.
It prepares the window, loads shaders, and sets up the graphics buffers.
*/
init_engine :: proc() {
	context.logger = log.create_console_logger()

	// setup window
	SUCCESS = init_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !SUCCESS {
		log.error("Failed to initialize window")
	} else {
		log.info("Window initialized successfully")
	}

	// setup shader
	shader, SUCCESS = init_shader(VERTEX_PATH, FRAGMENT_PATH)
	if !SUCCESS {
		log.error("Failed to compile shader file")
		return
	} else {
		log.info("Shader file compiled successfully")
	}

	// setup config
	enable_feature(gl.DEPTH_TEST)
	set_input_mode()
	set_glfw_callback()

	// setup texture
	texture_01 = init_texture(gl.TEXTURE_2D, gl.REPEAT, gl.LINEAR_MIPMAP_LINEAR, gl.LINEAR)
	SUCCESS = load_texture(TEXTURE_PATH_01, gl.TEXTURE_2D, gl.RGB, gl.RGB)
	if !SUCCESS {
		log.errorf("Failed to load texture: %v", texture_01.id)
	} else {
		log.infof("Texture loaded successfully: %v", texture_01.id)
	}

	// setup buffers
	vao, SUCCESS = create_VAO()
	if !SUCCESS {
		log.errorf("Failed to create vertex array object: %v", vao.id)
	} else {
		log.infof("Vertex array object created successfully: %v", vao.id)
	}

	vbo, SUCCESS = create_VBO()
	if !SUCCESS {
		log.errorf("Failed to create vertex buffer object: %v", vbo.id)
	} else {
		log.infof("Vertex buffer object created successfully: %v", vbo.id)
	}

	// bind buffers
 	SUCCESS = bind_VAO(&vao)
  	if !SUCCESS {
 		log.errorf("Failed to bind vertex array object: %v", vao.id)
   } else {
   		log.infof("Vertex array object binded successfully: %v", vao.id)
   }

  	SUCCESS = bind_VBO(&vbo, cube_vertices, gl.STATIC_DRAW)
   	if !SUCCESS {
  		log.errorf("Failed to bind vertex buffer object: %v", vbo.id)
    } else {
    		log.infof("Vertex buffer object binded successfully: %v", vbo.id)
    }

	// link buffers
	// position attribute
	stride : i32 = 5
	SUCCESS = link_attrib(0, 3, stride, 0)
	if !SUCCESS {
		log.errorf("Failed to link attributes to vertex array object: %v", vao.id)
	} else {
		log.infof("Linked attributes to vertex array object successfully: %v", vao.id)
	}

	// texture attribute
	SUCCESS = link_attrib(1, 2, stride, 3)
	if !SUCCESS {
		log.errorf("Failed to link attributes to vertex array object: %v", vao.id)
	} else {
		log.infof("Linked attributes to vertex array object successfully: %v", vao.id)
	}

	// setup camera
	SUCCESS = init_camera(&camera)
	if !SUCCESS {
		log.error("Failed to initialize camera")
	} else {
		log.info("Camera initialize successfully")
	}

	camera.aspect_ratio = {f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)}
}

/*
Cleans up the mess.
*/
delete_engine :: proc() {
	delete_VBO(&vbo)
	delete_VAO(&vao)
	delete_window()
}

/*
Clears the screen and updates the perspective for the next frame.
This makes sure the camera is looking at the right spot before draw.
*/
pre_render_engine :: proc() {
	clear_window()
	set_current_window_size()

	activate_texture(gl.TEXTURE0)
	bind_texture(gl.TEXTURE_2D, texture_01)

	use_shader(shader)
	camera_projection := get_camera_mode(.PERSPECTIVE, &camera)
	set_uniform(shader, "projection", &camera_projection)

	camera_view := get_camera_view(&camera)
	set_uniform(shader, "view", &camera_view)
}

/*
Draws the 3D scene geometry onto the screen.
*/
render_engine :: proc() {
	bind_VAO(&vao)
	for i in 0..<10 {
		init_transform(&cube_transform)
		angle := 20.0 * i
		move(cube_positions[i], &cube_transform)
		rotate(f32(angle), {1.0, 0.3, 0.5}, &cube_transform)
		apply_transform(shader, &cube_transform)
		gl.DrawArrays(gl.TRIANGLES, 0, 36)
	}
}

/*
Takes the finished drawing and presents it onto monitor.
*/
post_render_engine :: proc() {
	swap_buffer_window()
}

/*
Configures hardware callbacks for mouse and scroll events.
*/
set_glfw_callback :: proc() {
	glfw.SetWindowUserPointer(window, &camera)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, mouse_scroll_callback)
}

/*
Updates the engine timing and handles user input changes.
*/
process_input :: proc() {
	set_deltatime()
	close_window(window)
	move_camera(&camera)
	reset_camera(&camera)
}

/*
Wipes the window clean with a background color to start a new frame.
*/
clear_window :: proc() {
	gl.ClearColor(0.20, 0.20, 0.20, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

/*
Turns on a specific graphics setting.
*/
enable_feature :: proc(cap: u32)  {
	gl.Enable(cap)
}
