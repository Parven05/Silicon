package silicon

import "vendor:glfw"
import la "core:math/linalg"

process_input :: proc(window: glfw.WindowHandle, camera: ^Camera) {
	// close window
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}

	base_camera_speed := 0.06
	camera_speed_multiplier := 2.0
	current_camera_speed := base_camera_speed

	// increase & revert camera speed based on shift state
	if (glfw.GetKey(window, glfw.KEY_LEFT_SHIFT) == glfw.PRESS) {
		current_camera_speed = base_camera_speed * camera_speed_multiplier
	} else if (glfw.GetKey(window, glfw.KEY_LEFT_SHIFT) == glfw.RELEASE) {
		current_camera_speed = base_camera_speed
	}

	// move camera
	if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) {
		camera.pos += f32(current_camera_speed) * camera.target
	} else if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS) {
		camera.pos -= f32(current_camera_speed) * camera.target
	} else if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS) {
		camera.pos -= la.normalize(la.cross(camera.target, camera.up)) * f32(current_camera_speed)
	} else if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS) {
		camera.pos += la.normalize(la.cross(camera.target, camera.up)) * f32(current_camera_speed)
	}
}
