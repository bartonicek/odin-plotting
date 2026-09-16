package geometry

import "base:runtime"

// A polyline through the vertices (xs[i], ys[i]). The vertex slices are
// borrowed, not owned: `delete` on a Lines frees the line records only.
Line :: struct {
	xs: []f64,
	ys: []f64,
}

Lines :: #soa[]Line

lines :: proc(
	n: int,
	allocator := context.allocator,
) -> (
	lines: Lines,
	err: runtime.Allocator_Error,
) #optional_allocator_error {

	assert(n > 0, "the number of lines must be positive")
	lines = make(#soa[]Line, n, allocator) or_return
	return lines, nil
}
