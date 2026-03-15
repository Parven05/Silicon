package silicon

import la "core:math/linalg"
import ma "core:math"

Camera :: struct {
	pos:   la.Vector3f32,
	target: la.Vector3f32,
	up:    la.Vector3f32,
}

Projection	::	struct {
	fov:   f32,
	aspect_ratio: la.Vector2f32,
	near:  f32,
	far:   f32,
}

Camera_mode :: enum {
	PERSPECTIVE,
	ORTHOGRAPHIC,
}

init_camera :: proc(camera: ^Camera, p: ^Projection) {
	// default values
	camera.pos = {0.0, 0.0, 3.0}
	camera.target = {0.0, 0.0, -1.0}
	camera.up = {0.0, 1.0, 0.0}
	p.fov = ma.to_radians_f32(45.0)
	p.near = 0.1
	p.far = 100.0
}

@require_results
get_camera_mode :: proc(cam_mode: Camera_mode, p: ^Projection) -> la.Matrix4f32  {
	switch cam_mode {
	case .PERSPECTIVE:
		return la.matrix4_perspective_f32(p.fov, f32(p.aspect_ratio.x) / f32(p.aspect_ratio.y), p.near, p.far)
	// not yet implement ortho logic
	case .ORTHOGRAPHIC:
		return 0
	}
	return 0
}

@require_results
get_camera_view :: proc(camera: ^Camera) -> la.Matrix4f32 {
	return la.matrix4_look_at_f32(camera.pos, camera.target, camera.up)
}

@require_results
get_camera_move_view :: proc(camera: ^Camera) -> la.Matrix4f32 {
	return la.matrix4_look_at_f32(camera.pos, camera.pos + camera.target, camera.up)
}
