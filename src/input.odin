package silicon

import "vendor:glfw"
import ma "core:math"
import la "core:math/linalg"

close_window_esc :: proc(window: glfw.WindowHandle) {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
}

move_camera_keys :: proc(camera: ^Camera) {
	base_camera_speed := 4.0 * f32(delta_time)
	camera_speed_multiplier := 6.0
	current_camera_speed := base_camera_speed

	// increase & revert camera speed based on shift state
	if (glfw.GetKey(window, glfw.KEY_LEFT_SHIFT) == glfw.PRESS) {
		current_camera_speed = base_camera_speed * f32(camera_speed_multiplier)
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

@(private="file") last_x := f32(WINDOW_WIDTH) / 2.0
@(private="file") last_y := f32(WINDOW_HEIGHT) / 2.0
@(private="file") first_mouse := true

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

	camera_ptr.rot.y += x_offset
	camera_ptr.rot.x += y_offset

	// limit pitch
	if (camera_ptr.rot.x > 89.0) do camera_ptr.rot.x = 89.0
	if (camera_ptr.rot.x < -89.0) do camera_ptr.rot.x = -89.0

	direction : la.Vector3f32
	direction.x = ma.cos(ma.to_radians_f32(camera_ptr.rot.y)) * ma.cos(ma.to_radians_f32(camera_ptr.rot.x))
	direction.y = ma.sin(ma.to_radians_f32(camera_ptr.rot.x))
	direction.z = ma.sin(ma.to_radians_f32(camera_ptr.rot.y)) * ma.cos(ma.to_radians_f32(camera_ptr.rot.x))
	camera_ptr.target = la.normalize(direction)
}

mouse_scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
	camera_ptr := (^Camera)(glfw.GetWindowUserPointer(window))

	// limit field of view
	camera_ptr.fov -= f32(y_offset)
	if (camera_ptr.fov < 1.0) do camera_ptr.fov = 1.0
	if (camera_ptr.fov > 45.0) do camera_ptr.fov = 45.0
}
