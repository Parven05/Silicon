package silicon

import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Silicon"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 4

window: glfw.WindowHandle

vertices := [?]f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}

fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Implicit context needs to be set explicitly for "c" procs
	// if inside it we're calling non-c procs (render in this case)
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
}

vertex_shader_source := `
#version 460 core

layout (location = 0) in vec3 aPos;

void main() {
    gl_Position = vec4(aPos, 1.0);
}
`
frag_shader_source := `
#version 460 core
out vec4 FragColor;

void main() {
    FragColor = vec4(1.0, 0.5, 0.2, 1.0);
}
`

vertex_source_ptr := cstring(raw_data(vertex_shader_source))
frag_source_ptr := cstring(raw_data(frag_shader_source))

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

	// Buffer
	VBO, VAO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	// bind vertex array object
	gl.BindVertexArray(VAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	// Linking vertex data
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// Compile Shaders
	vertex_shader: u32
	vertex_shader = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex_shader, 1, &vertex_source_ptr, nil)
	gl.CompileShader(vertex_shader)

	success: i32
	gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(vertex_shader, 512, nil, &info_log[0])
		log.errorf("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n%s", info_log)
	}

	frag_shader: u32
	frag_shader = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(frag_shader, 1, &frag_source_ptr, nil)
	gl.CompileShader(frag_shader)

	gl.GetShaderiv(frag_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(vertex_shader, 512, nil, &info_log[0])
		log.errorf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n%s", info_log)
	}

	// Shader Program
	shader_program: u32
	shader_program = gl.CreateProgram()
	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, frag_shader)
	gl.LinkProgram(shader_program)

	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetProgramInfoLog(shader_program, 512, nil, &info_log[0])
		log.errorf("ERROR::SHADER::LINKING::FAILED\n%s", info_log)
	}


	defer gl.DeleteShader(vertex_shader)
	defer gl.DeleteShader(frag_shader)


	for (!glfw.WindowShouldClose(window)) {
		process_input(window)

		gl.ClearColor(0, 0, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)
		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()

	}
}
