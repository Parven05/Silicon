package silicon

import im "libs:imgui"
import "libs:imgui/imgui_impl_glfw"
import "libs:imgui/imgui_impl_opengl3"

init_ui :: proc() {
	im.CreateContext()
	imgui_impl_glfw.InitForOpenGL(window, true)
	imgui_impl_opengl3.Init("#version 460")
}

delete_ui :: proc() {
	imgui_impl_opengl3.Shutdown()
	imgui_impl_glfw.Shutdown()
	im.DestroyContext()
}

pre_render_ui :: proc() {
	// ui default
	imgui_impl_opengl3.NewFrame()
	imgui_impl_glfw.NewFrame()
	im.NewFrame()
}

draw_status_bottom_bar_ui :: proc(camera: ^Camera) {
	bar_height : f32 = 25.0
	im.SetNextWindowPos({0, f32(current_window_height) - bar_height})
	im.SetNextWindowSize({f32(current_window_width) + 2, bar_height})

	flags := im.WindowFlags{.NoTitleBar, .NoResize, .NoMove, .NoScrollbar, .NoBackground}

	im.Begin("Status Bar", nil, flags)
	draw_f32_colored_ui("FPS", "%.2f", f32(1.0 / delta_time))
	im.SameLine()
	im.Text("|")
	im.SameLine()

	draw_f32_colored_ui("DT", "%.4f", f32(delta_time))
	im.SameLine()
	im.Text("|")
	im.SameLine()

	im.Text("=O=")
	im.SameLine()
	draw_vec3_colored_ui("Pos", camera.pos)

	im.SameLine()
	im.Text("*")
	im.SameLine()
	draw_vec2_colored_ui("Rot", camera.rot)

	im.SameLine()
	draw_f32_colored_ui("Fov", "%.2f", camera.fov)
	im.End()
}

render_ui :: proc() {
	im.Render()
	imgui_impl_opengl3.RenderDrawData(im.GetDrawData())
}

// utility functions
draw_vec3_colored_ui :: proc(label: string, v: [3]f32) {
    im.Text("%s: ", label)
    im.SameLine(0, 0)

    im.TextColored({1.0, 0.4, 0.4, 1.0}, "%.2f", v.x) // X - Red
    im.SameLine(0, 0)
    im.Text(", ")
    im.SameLine(0, 2)

    im.TextColored({0.4, 1.0, 0.4, 1.0}, "%.2f", v.y) // Y - Green
    im.SameLine(0, 0)
    im.Text(", ")
    im.SameLine(0, 2)

    im.TextColored({0.4, 0.4, 1.0, 1.0}, "%.2f", v.z) // Z - Blue
    im.SameLine(0, 0)
}

draw_vec2_colored_ui :: proc(label: string, v: [3]f32) {
    im.Text("%s: ", label)
    im.SameLine(0, 0)

    im.TextColored({1.0, 0.4, 0.4, 1.0}, "%.2f", v.x) // X - Red
    im.SameLine(0, 0)
    im.Text(", ")
    im.SameLine(0, 2)

    im.TextColored({0.4, 1.0, 0.4, 1.0}, "%.2f", v.y) // Y - Green
    im.SameLine(0, 0)
}

draw_f32_colored_ui :: proc(label: string, format: cstring, v: f32) {
    im.Text("%s: ", label)
    im.SameLine(0, 0)

    im.TextColored({1.0, 1.0, 0.4, 1.0}, format, v) // X - Red
    im.SameLine(0, 4)
}
