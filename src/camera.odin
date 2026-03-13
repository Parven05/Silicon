package silicon
import la "core:math/linalg"
import ma "core:math"

Camera :: struct {
	pos:   la.Vector3f32,
	front: la.Vector3f32,
	up:    la.Vector3f32,
	fov:   f32,
	near:  f32,
	far:   f32,
	mode:  Camera_mode,
}

Camera_mode :: enum {
	PERSPECTIVE,
	ORTHOGRAPHIC,
}

@(require_results)
set_camera_mode :: proc(cam_mode: Camera_mode, camera: ^Camera) -> matrix[4, 4]f32 {

	switch cam_mode {
	case .PERSPECTIVE:
		// default values
		camera.fov = ma.to_radians_f32(45.0)
		camera.near = 0.1
		camera.far = 100.0
		return la.matrix4_perspective_f32(camera.fov, f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT), camera.near, camera.far)
	// not yet implement ortho logic
	case .ORTHOGRAPHIC:
		return 0
	}
	return 0
}

@(require_results)
init_camera :: proc(camera: ^Camera) -> matrix[4, 4]f32 {
	view := la.matrix4_look_at_f32(camera.pos, camera.front, camera.up)
	return view
}
