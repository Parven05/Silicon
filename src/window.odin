package silicon

import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

window: glfw.WindowHandle

@(private="file") GL_VERSION_MAJOR :: 4
@(private="file") GL_VERSION_MINOR :: 4

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

	// load GLAD loader
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	log.info(gl.GetString(gl.VERSION))

	glfw.SetFramebufferSizeCallback(window, fb_size_callback)

	return true

}

window_close :: proc() -> bool {

	for (!glfw.WindowShouldClose(window)) {
		glfw.SwapBuffers(window)
		glfw.PollEvents()

		return false
	}
	return true
}

delete_window :: proc() {
	glfw.Terminate()
}

@(private="file")
fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
