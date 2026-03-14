package silicon

import la "core:math/linalg"
import ma "core:math"
import "vendor:glfw"

Camera :: struct {
	pos:   la.Vector3f32,
	front: la.Vector3f32,
	up:    la.Vector3f32,
	fov:   f32,
	near:  f32,
	far:   f32,
}

Camera_mode :: enum {
	PERSPECTIVE,
	ORTHOGRAPHIC,
}

init_camera :: proc(camera: ^Camera) {
	camera.pos = {0.0, 0.0, 0.0}
	camera.front = {0.0, 0.0, 0.0}
	camera.up = {0.0, 0.1, 0.0}
}

set_camera_mode :: proc(cam_mode: Camera_mode, camera: ^Camera, shader: Shader)  {
	w, h := glfw.GetWindowSize(window)
	switch cam_mode {
	case .PERSPECTIVE:
		camera.fov = ma.to_radians_f32(45.0)
		camera.near = 0.1
		camera.far = 100.0
		projection := la.matrix4_perspective_f32(camera.fov, f32(w) / f32(h), camera.near, camera.far)
		set_mat4_f(shader, "projection", &projection)
	// not yet implement ortho logic
	case .ORTHOGRAPHIC:
	}
}

set_camera_view :: proc(camera: ^Camera, shader: Shader) {
	view := la.matrix4_look_at_f32(camera.pos, camera.front, camera.up)
	set_mat4_f(shader, "view", &view)
}
