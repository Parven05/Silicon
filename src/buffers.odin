/*
Handles the creation, binding, and deletion of OpenGL memory objects
like Vertex Buffers (VBO) and Vertex Arrays (VAO).
*/
package silicon

import gl "vendor:OpenGL"

/*
Represents a block of memory on the GPU that stores vertex data.
*/
VBO::struct {
    id: u32,
}

/*
Creates a new VBO on the graphics card.
*/
@require_results
create_VBO::proc() -> (VBO, bool) {
    vbo_id: u32
    gl.GenBuffers(1, &vbo_id)
    return VBO{id = vbo_id}, true
}

/*
Connects the buffer and uploads raw vertex data to the GPU.
*/
bind_VBO::proc(vbo:^VBO, vertices: []f32, usage:u32) -> (bool) {
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo.id)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices) * len(vertices), raw_data(vertices), usage)
    return true
}

/*
Deletes the VBO and frees the memory on the GPU.
*/
delete_VBO::proc(vbo:^VBO) {
    gl.DeleteBuffers(1, &vbo.id)
}

/*
Represents the state and configuration of your vertex attributes.
*/
VAO::struct {
    id: u32,
}

/*
Creates a new VAO to store vertex configuration state.
*/
@require_results
create_VAO::proc() -> (VAO, bool) {
    vao_id: u32
    gl.GenVertexArrays(1, &vao_id)
    return VAO{id = vao_id}, true
}

/*
Activates the VAO for the current drawing operations.
*/
bind_VAO::proc(vao:^VAO) -> (bool) {
    gl.BindVertexArray(vao.id)
    return true
}

/*
Links a specific vertex attribute (like position or color) to the pipeline.
*/
link_attrib::proc(index: u32, size, stride: i32, offset: u32) -> (bool) {
	gl.VertexAttribPointer(index, size, gl.FLOAT, false, stride * size_of(f32), uintptr(offset * size_of(f32)))
	gl.EnableVertexAttribArray(index)
	return true
}

/*
Deletes the VAO handle.
*/
delete_VAO::proc(vao:^VAO) {
    gl.DeleteVertexArrays(1, &vao.id)
}

/*
Stores indices that tell the GPU which vertices to reuse for drawing.
*/
EBO::struct {
    id: u32,
}

/*
Creates a new EBO.
*/
@require_results
create_EBO::proc() -> (EBO, bool) {
    ebo_id: u32
    gl.GenBuffers(1, &ebo_id)
    return EBO{id = ebo_id}, true
}

/*
Uploads index data to the GPU for drawing indexed geometry.
*/
bind_EBO::proc(ebo:^EBO, indices: []u32, usage:u32) -> (bool) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo.id)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices) * len(indices), raw_data(indices), usage)
    return true
}

/*
Deletes the EBO handle.
*/
delete_EBO::proc(ebo:^EBO) {
    gl.DeleteBuffers(1, &ebo.id)
}
