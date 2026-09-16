package geometry

import "base:runtime"

Rect :: struct {
	x0: f64,
	y0: f64,
	x1: f64,
	y1: f64,
}

Rects :: #soa[]Rect

rects :: proc(
	n: int,
	allocator := context.allocator,
) -> (
	rects: Rects,
	err: runtime.Allocator_Error,
) #optional_allocator_error {

	assert(n > 0, "the number of rects must be positive")
	rects = make(#soa[]Rect, n, allocator) or_return
	return rects, nil
}
