package silicon

import "core:log"
import "core:math"
import gl "vendor:OpenGL"
import "vendor:glfw"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Silicon"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 4

window: glfw.WindowHandle

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

main :: proc() {

	context.logger = log.create_console_logger()

	if !glfw.Init() {
		log.error("Failed to initialize GLFW")
		return
	}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, nil, nil)

	if window == nil {
		log.error("Failed to create GLFW Window")
		glfw.Terminate()
		return
	}
	defer glfw.Terminate()

	log.info("GLFW window created successfully")

	glfw.MakeContextCurrent(window)

	// Load OpenGL functions
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	log.info(gl.GetString(gl.VERSION))

	glfw.SetFramebufferSizeCallback(window, fb_size_callback)

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


	for (!glfw.WindowShouldClose(window)) {
		process_input(window)

		gl.ClearColor(0, 0, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		use(shader)

		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()

	}
}

fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
}
