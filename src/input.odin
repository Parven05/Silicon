package silicon

import "vendor:glfw"

process_input :: proc() {
	close_window(window)
}

close_window :: proc(window: glfw.WindowHandle) {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
}
