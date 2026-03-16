package silicon

import "vendor:glfw"
import ma "core:math"
import la "core:math/linalg"

yaw : f32 = -90.0
pitch : f32 = 0.0
last_x := f32(WINDOW_WIDTH) / 2.0
last_y := f32(WINDOW_HEIGHT) / 2.0
first_mouse := true

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

mouse_callback :: proc "c" (window: glfw.WindowHandle, x_pos: f64, y_pos: f64) {

	camera_ptr := (^Camera)(glfw.GetWindowUserPointer(window))

	if (first_mouse) {
		last_x = f32(x_pos)
		last_y = f32(y_pos)
		first_mouse = false
	}

	x_offset := f32(x_pos) - last_x
	y_offset := last_y - f32(y_pos)
	last_x = f32(x_pos)
	last_y = f32(y_pos)

	sensitivity : f32 = 0.1
	x_offset *= sensitivity
	y_offset *= sensitivity

	yaw += x_offset
	pitch += y_offset

	if(pitch > 89.0) {
		pitch = 89.0
	} else if (pitch < -89.0) {
		pitch = -89.0
	}

	direction : la.Vector3f32
	direction.x = ma.cos(ma.to_radians_f32(yaw)) * ma.cos(ma.to_radians_f32(pitch))
	direction.y = ma.sin(ma.to_radians_f32(pitch))
	direction.z = ma.sin(ma.to_radians_f32(yaw)) * ma.cos(ma.to_radians_f32(pitch))
	camera_ptr.target = la.normalize(direction)
}

mouse_scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {

	camera_ptr := (^Camera)(glfw.GetWindowUserPointer(window))

	camera_ptr.fov -= f32(y_offset)
	if (camera_ptr.fov < 1.0) {
		camera_ptr.fov = 1.0
	} else if (camera_ptr.fov > 45.0) {
		camera_ptr.fov = 45.0
	}
}
