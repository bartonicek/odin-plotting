package scatter_web

import backend "../src/backends/raylib"
import "../src/expanse"
import "../src/geometry"
import "../src/scale"
import "core:c"
import "core:encoding/json"
import "core:log"
import rl "vendor:raylib"

INITIAL_WIDTH :: 800
INITIAL_HEIGHT :: 600
MARGIN :: 60
FONT_LOAD_SIZE :: 48
LABEL_SIZE :: 20

// There is no filesystem in the browser, so the data and the font are
// embedded into the binary at compile time.
MTCARS_JSON := #load("../data/mtcars.json")
FONT_TTF := #load("../assets/DejaVuSans.ttf")

Car :: struct {
	model: string,
	mpg:   f64,
	cyl:   int,
	disp:  f64,
	hp:    int,
	drat:  f64,
	wt:    f64,
	qsec:  f64,
	vs:    int,
	am:    int,
	gear:  int,
	carb:  int,
}

// `update` is called once per frame from JavaScript, so anything that has to
// survive between frames lives here rather than on a stack frame.
@(private = "file")
state: struct {
	run:              bool,
	cars:             []Car,
	wt, mpg, scratch: []f64,
	x_scale, y_scale: scale.Scale,
	points:           geometry.Points,
	font:             rl.Font,
	width, height:    f64,
	selection:        geometry.Rect,
	selecting:        bool,
}

init :: proc() {
	state.run = true

	if err := json.unmarshal(MTCARS_JSON, &state.cars); err != nil {
		log.errorf("could not parse the embedded mtcars.json: %v", err)
		state.run = false
		return
	}
	n := len(state.cars)

	state.wt = make([]f64, n)
	state.mpg = make([]f64, n)
	state.scratch = make([]f64, n)

	for car, i in state.cars {
		state.wt[i] = car.wt
		state.mpg[i] = car.mpg
	}

	// Empty expanses to start; the domains are fitted to the data here and
	// `layout` sizes the codomains to the window.
	empty: expanse.Expanse = expanse.continuous(0, 0)
	state.x_scale = scale.new(empty, empty, {zero = 0.1, one = 0.9})
	// Screen y grows downward, so the mpg axis runs backward.
	state.y_scale = scale.new(empty, empty, {zero = 0.1, one = 0.9, direction = .Backward})

	scale.train_domain(&state.x_scale, state.wt)
	scale.train_domain(&state.y_scale, state.mpg)

	state.points = geometry.points(n)
	for i in 0 ..< n {
		state.points[i].radius = 5
	}

	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(INITIAL_WIDTH, INITIAL_HEIGHT, "mtcars: weight vs mpg")

	state.font = rl.LoadFontFromMemory(
		".ttf",
		raw_data(FONT_TTF),
		i32(len(FONT_TTF)),
		FONT_LOAD_SIZE,
		nil,
		0,
	)
	rl.SetTextureFilter(state.font.texture, .BILINEAR)

	log.infof("loaded %d cars", n)
	layout(f64(rl.GetScreenWidth()), f64(rl.GetScreenHeight()))
}

// Re-maps the data through the scales for the current plot size. Only the
// codomains move; the data domains are untouched.
@(private = "file")
layout :: proc(width: f64, height: f64) {
	state.width = width
	state.height = height

	expanse.set_min_max(
		&state.x_scale.codomain.(expanse.ExpanseContinuous),
		MARGIN,
		width - MARGIN,
	)
	expanse.set_min_max(
		&state.y_scale.codomain.(expanse.ExpanseContinuous),
		MARGIN,
		height - MARGIN,
	)

	remap()
}

@(private = "file")
remap :: proc() {
	n := len(state.points)
	scale.pushforward(&state.x_scale, state.points.x[:n], state.wt, state.scratch)
	scale.pushforward(&state.y_scale, state.points.y[:n], state.mpg, state.scratch)
}

update :: proc() {
	handle_reset()
	handle_pan()
	handle_selection()

	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)

	w := i32(state.width)
	h := i32(state.height)
	rl.DrawLine(MARGIN, h - MARGIN, w - MARGIN, h - MARGIN, rl.DARKGRAY)
	rl.DrawLine(MARGIN, MARGIN, MARGIN, h - MARGIN, rl.DARKGRAY)

	backend.draw(state.points, backend.AestheticConfig{fill = rl.Color{200, 30, 30, 220}})

	if state.selecting {
		backend.draw(
			state.selection,
			backend.AestheticConfig {
				fill = rl.Color{30, 90, 200, 60},
				color = rl.Color{30, 90, 200, 180},
			},
		)
	}

	x_label: cstring = "wt (1000 lbs)"
	x_extent := rl.MeasureTextEx(state.font, x_label, LABEL_SIZE, 0)
	rl.DrawTextEx(
		state.font,
		x_label,
		{f32(state.width) / 2 - x_extent.x / 2, f32(state.height) - MARGIN + 24},
		LABEL_SIZE,
		0,
		rl.DARKGRAY,
	)

	y_label: cstring = "mpg"
	y_extent := rl.MeasureTextEx(state.font, y_label, LABEL_SIZE, 0)
	rl.DrawTextPro(
		state.font,
		y_label,
		{22, f32(state.height) / 2 + y_extent.x / 2},
		{},
		-90,
		LABEL_SIZE,
		0,
		rl.DARKGRAY,
	)

	rl.EndDrawing()
}

// Drags are clamped to the plotting area so the rectangle cannot spill into
// the margins where the axis labels live.
@(private = "file")
handle_selection :: proc() {
	mouse := rl.GetMousePosition()
	x := clamp(f64(mouse.x), MARGIN, state.width - MARGIN)
	y := clamp(f64(mouse.y), MARGIN, state.height - MARGIN)

	if rl.IsMouseButtonPressed(.LEFT) {
		state.selecting = true
		state.selection = {
			x0 = x,
			y0 = y,
			x1 = x,
			y1 = y,
		}
	}

	if state.selecting {
		state.selection.x1 = x
		state.selection.y1 = y
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		state.selecting = false
	}
}

@(private = "file")
handle_reset :: proc() {
	if !rl.IsKeyPressed(.R) {
		return
	}

	scale.reset(&state.x_scale)
	scale.reset(&state.y_scale)
	remap()
}

// `scale.move` takes an amount in unit space, so a pixel delta is divided by
// the width of the codomain it is dragged across.
@(private = "file")
handle_pan :: proc() {
	if !rl.IsMouseButtonDown(.RIGHT) {
		return
	}

	delta := rl.GetMouseDelta()
	if delta.x == 0 && delta.y == 0 {
		return
	}

	x_codomain := state.x_scale.codomain.(expanse.ExpanseContinuous)
	y_codomain := state.y_scale.codomain.(expanse.ExpanseContinuous)
	x_span := x_codomain.max - x_codomain.min
	y_span := y_codomain.max - y_codomain.min

	if x_span <= 0 || y_span <= 0 {
		return
	}

	scale.move(&state.x_scale, f64(delta.x) / x_span)
	scale.move(&state.y_scale, f64(delta.y) / y_span)

	remap()
}

parent_window_size_changed :: proc(w: int, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h))
	layout(f64(w), f64(h))
}

shutdown :: proc() {
	delete(state.cars)
	delete(state.wt)
	delete(state.mpg)
	delete(state.scratch)
	delete(state.points)
	rl.UnloadFont(state.font)
	rl.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			state.run = false
		}
	}

	return state.run
}
