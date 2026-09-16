package expanse

import "base:runtime"
import "core:math"
import "core:slice"

ExpansePoint :: struct {
	labels: []string,
}

set_labels_point :: proc(
	expanse: ^ExpansePoint,
	labels: []string,
	allocator := context.allocator,
) -> (
	err: runtime.Allocator_Error,
) {
	assert(len(labels) > 0, "cannot set a point expanse to no labels")

	clone := slice.clone(labels, allocator) or_return

	delete(expanse.labels, allocator)
	expanse.labels = clone
	return nil
}

normalize_point :: proc(expanse: ^ExpansePoint, result: []f64, input: []string) {
	assert(len(result) == len(input))
	n := len(expanse.labels)
	for i in 0 ..< len(input) {
		index, found := slice.linear_search(expanse.labels, input[i])
		assert(found, "normalize: label is not present in the expanse")
		result[i] = n == 1 ? 0.5 : f64(index) / f64(n - 1)
	}
}

unnormalize_point :: proc(expanse: ^ExpansePoint, result: []string, input: []f64) {
	assert(len(result) == len(input))
	n := len(expanse.labels)
	for i in 0 ..< len(input) {
		index := clamp(int(math.round(input[i] * f64(n - 1))), 0, n - 1)
		result[i] = expanse.labels[index]
	}
}

train_point :: proc(
	expanse: ^ExpansePoint,
	values: []string,
	allocator := context.allocator,
) -> (
	err: runtime.Allocator_Error,
) {
	assert(len(values) > 0, "cannot train a point expanse on no data")

	labels := make([dynamic]string, 0, len(values), allocator) or_return
	defer if err != nil do delete(labels)

	for value in values {
		if _, found := slice.linear_search(labels[:], value); !found {
			_, err = append(&labels, value)
			if err != nil do return err
		}
	}

	delete(expanse.labels, allocator)
	expanse.labels = labels[:]
	return nil
}

destroy_point :: proc(expanse: ^ExpansePoint, allocator := context.allocator) {
	delete(expanse.labels, allocator)
	expanse^ = {}
}
