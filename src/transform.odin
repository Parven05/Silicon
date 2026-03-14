package silicon

import ma "core:math"
import la "core:math/linalg"

Transform :: struct {
	model : la.Matrix4f32
}

init_transform :: proc(trans: ^Transform) {
	trans.model = la.MATRIX4F32_IDENTITY
}

move :: proc(obj: la.Vector3f32, trans: ^Transform) {
	trans.model = trans.model * la.matrix4_translate_f32(obj)
}

rotate :: proc(angle: f32, v:la.Vector3f32, trans: ^Transform) {
	trans.model = trans.model * la.matrix4_rotate_f32(ma.to_radians(angle), v)
}

scale :: proc(v:la.Vector3f32, trans: ^Transform) {
	trans.model = trans.model * la.matrix4_scale_f32(v)
}

apply_transform :: proc(shader: Shader, trans: ^Transform) {
	set_uniform(shader, "model", &trans.model)
}
