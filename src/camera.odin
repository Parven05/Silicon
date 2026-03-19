// 8
package silicon

import la "core:math/linalg"
import ma "core:math"

Camera :: struct {
	pos:   			la.Vector3f32,
	rot: 			la.Vector3f32,
	target: 		la.Vector3f32,
	up:    			la.Vector3f32,
	fov:   			f32,
	aspect_ratio: 	la.Vector2f32,
	near:  			f32,
	far:   			f32,
}

Camera_mode :: enum {
	PERSPECTIVE,
	ORTHOGRAPHIC,
}

init_camera :: proc(camera: ^Camera) -> (bool) {
	pitch : f32 = 0.0
	yaw : f32 = -90.0

	camera.pos = {0.0, 0.0, 3.0}
	camera.rot = {pitch, yaw, 0.0}
	camera.target = {0.0, 0.0, -1.0}
	camera.up = {0.0, 1.0, 0.0}
	camera.fov = 45.0
	camera.near = 0.1
	camera.far = 100.0
	return true
}

@require_results
get_camera_mode :: proc(cam_mode: Camera_mode, camera: ^Camera) -> la.Matrix4f32  {
	switch cam_mode {
	case .PERSPECTIVE:
		return la.matrix4_perspective_f32(ma.to_radians_f32(camera.fov), f32(camera.aspect_ratio.x) / f32(camera.aspect_ratio.y), camera.near, camera.far)
	// not yet implement ortho logic
	case .ORTHOGRAPHIC:
		return 0
	}
	return 0
}

@require_results
get_camera_view :: proc(camera: ^Camera) -> la.Matrix4f32 {
	return la.matrix4_look_at_f32(camera.pos, camera.pos + camera.target, camera.up)
}
