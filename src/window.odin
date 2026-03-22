package silicon

import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

@(private="file") GL_VERSION_MAJOR :: 4
@(private="file") GL_VERSION_MINOR :: 4

window: glfw.WindowHandle

WINDOW_TITLE :: "Silicon"
WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

current_window_width : i32
current_window_height : i32

last_frame := 0.0
delta_time := 0.0

init_window :: proc(window_width: i32, window_height: i32, window_title: cstring) -> (bool) {
	if !glfw.Init() {
		return false
	}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	window = glfw.CreateWindow(window_width, window_height, window_title, nil, nil)

	if window == nil {
		glfw.Terminate()
		return false
	}
	glfw.MakeContextCurrent(window)

	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	log.info(gl.GetString(gl.VERSION))

	glfw.SetFramebufferSizeCallback(window, fb_size_callback)
	return true
}

delete_window :: proc() {
	glfw.Terminate()
}

window_close :: proc() -> bool {
	for (!glfw.WindowShouldClose(window)) {
		return false
	}
	return true
}

swap_buffer_window :: proc() {
	glfw.SwapBuffers(window)
	glfw.PollEvents()
}

// utility functions
set_deltatime :: proc () {
	current_frame := glfw.GetTime()
	delta_time = current_frame - last_frame
	last_frame = current_frame
}

set_current_window_size :: proc() {
	current_window_width, current_window_height = glfw.GetWindowSize(window)
}

@(private="file")
fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
