package silicon

import gl "vendor:OpenGL"

VBO::struct {
    id: u32,
}

@require_results
create_VBO::proc() -> (VBO, bool) {
    vbo_id: u32
    gl.GenBuffers(1, &vbo_id)
    return VBO{id = vbo_id}, true
}

bind_VBO::proc(vbo:^VBO, vertices: []f32, usage:u32) -> (bool) {
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo.id)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices) * len(vertices), raw_data(vertices), usage)
    return true
}

delete_VBO::proc(vbo:^VBO) {
    gl.DeleteBuffers(1, &vbo.id)
}

VAO::struct {
    id: u32,
}

@require_results
create_VAO::proc() -> (VAO, bool) {
    vao_id: u32
    gl.GenVertexArrays(1, &vao_id)
    return VAO{id = vao_id}, true
}

bind_VAO::proc(vao:^VAO) -> (bool) {
    gl.BindVertexArray(vao.id)
    return true
}

link_attrib::proc(index: u32, size, stride: i32, offset: u32) -> (bool) {
	gl.VertexAttribPointer(index, size, gl.FLOAT, false, stride * size_of(f32), uintptr(offset * size_of(f32)))
	gl.EnableVertexAttribArray(index)
	return true
}

delete_VAO::proc(vao:^VAO) {
    gl.DeleteVertexArrays(1, &vao.id)
}

EBO::struct {
    id: u32,
}

@require_results
create_EBO::proc() -> (EBO, bool) {
    ebo_id: u32
    gl.GenBuffers(1, &ebo_id)
    return EBO{id = ebo_id}, true
}

bind_EBO::proc(ebo:^EBO, indices: []u32, usage:u32) -> (bool) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo.id)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices) * len(indices), raw_data(indices), usage)
    return true
}

delete_EBO::proc(ebo:^EBO) {
    gl.DeleteBuffers(1, &ebo.id)
}
