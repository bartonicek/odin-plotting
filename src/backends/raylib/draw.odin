package backend_raylib

import "../../geometry"
import rl "vendor:raylib"

DEFAULT_LINE_THICKNESS :: 1

AestheticConfig :: struct {
	fill:           Maybe(rl.Color),
	color:          Maybe(rl.Color),
	line_thickness: Maybe(f32),
}

draw :: proc {
	draw_points,
	draw_lines,
	draw_rect,
	draw_rects,
}

draw_points :: proc(points: geometry.Points, config: AestheticConfig) {
	fill, has_fill := config.fill.?
	border, has_border := config.color.?

	for point in points {
		x := f32(point.x)
		y := f32(point.y)
		radius := f32(point.radius)

		if has_fill {
			rl.DrawCircleV({x, y}, radius, fill)
		}

		if has_border {
			rl.DrawCircleLinesV({x, y}, radius, border)
		}
	}
}

draw_lines :: proc(lines: geometry.Lines, config: AestheticConfig) {
	stroke, has_stroke := config.color.?
	if !has_stroke {
		return
	}

	thickness := config.line_thickness.? or_else DEFAULT_LINE_THICKNESS

	for line in lines {
		n := min(len(line.xs), len(line.ys))

		for i in 1 ..< n {
			start := rl.Vector2{f32(line.xs[i - 1]), f32(line.ys[i - 1])}
			end := rl.Vector2{f32(line.xs[i]), f32(line.ys[i])}

			rl.DrawLineEx(start, end, thickness, stroke)
		}
	}
}

draw_rect :: proc(rect: geometry.Rect, config: AestheticConfig) {
	x := f32(min(rect.x0, rect.x1))
	y := f32(min(rect.y0, rect.y1))
	width := f32(abs(rect.x1 - rect.x0))
	height := f32(abs(rect.y1 - rect.y0))

	if fill, ok := config.fill.?; ok {
		rl.DrawRectangleRec({x, y, width, height}, fill)
	}

	if border, ok := config.color.?; ok {
		thickness := config.line_thickness.? or_else DEFAULT_LINE_THICKNESS
		rl.DrawRectangleLinesEx({x, y, width, height}, thickness, border)
	}
}

draw_rects :: proc(rects: geometry.Rects, config: AestheticConfig) {
	for rect in rects {
		draw_rect(rect, config)
	}
}
