package silicon

import "vendor:glfw"

process_input :: proc(window: glfw.WindowHandle) {

	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
}
