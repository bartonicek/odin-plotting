package utils

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:math/rand"
import "core:reflect"

untyped_len :: proc(value: any) -> int {
	if reflect.is_union(type_info_of(value.id)) {
		return reflect.length(reflect.get_union_variant(value))
	}
	return reflect.length(value)
}

// Uniform random values in [min, max)
random_vec :: proc(
	n: int,
	min, max: f64,
	allocator := context.allocator,
) -> (
	result: []f64,
	err: runtime.Allocator_Error,
) #optional_allocator_error {
	result = make([]f64, n, allocator) or_return
	for &v in result do v = rand.float64_range(min, max)
	return result, nil
}

@(require_results)
// Unwraps a value if it conforms to the expected type, or panics.
unwrap_or_panic :: proc(
	$T: typeid/[]$E,
	value: $V,
	loc := #caller_location,
) -> T where intrinsics.type_is_union(V),
	intrinsics.type_is_variant_of(V, T) {
	unwrapped, ok := value.(T)
	if !ok {
		op := loc.procedure
		expected := typeid_of(T)
		received := reflect.union_variant_typeid(value)
		fmt.panicf("%s: expected %v, got %v", op, expected, received, loc = loc)
	}
	return unwrapped
}
