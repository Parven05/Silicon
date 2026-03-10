package silicon

import "core:log"
import gl "vendor:OpenGL"
import "vendor:glfw"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 4

window: glfw.WindowHandle

init_window :: proc(window_width: i32, window_height: i32, window_title: cstring) {

	if !glfw.Init() {
		log.error("Failed to initialize GLFW")
		return
	}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window = glfw.CreateWindow(window_width, window_height, window_title, nil, nil)

	if window == nil {
		log.error("Failed to create GLFW Window")
		glfw.Terminate()
		return
	} else {
		log.info("GLFW window created successfully")
	}
	glfw.MakeContextCurrent(window)

	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	log.info(gl.GetString(gl.VERSION))

	glfw.SetFramebufferSizeCallback(window, fb_size_callback)

}

window_close :: proc() -> bool {

	for (!glfw.WindowShouldClose(window)) {
		process_input(window)

		glfw.SwapBuffers(window)
		glfw.PollEvents()

		return false
	}

	return true
}


delete_window :: proc() {
	glfw.Terminate()
}

fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
