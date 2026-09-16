package geometry

import "base:runtime"

Point :: struct {
	x:      f64,
	y:      f64,
	radius: f64,
}

Points :: #soa[]Point

points :: proc(
	n: int,
	allocator := context.allocator,
) -> (
	points: Points,
	err: runtime.Allocator_Error,
) #optional_allocator_error {
	assert(n > 0, "the number of points must be positive")
	points = make(#soa[]Point, n, allocator) or_return

	return points, nil
}
