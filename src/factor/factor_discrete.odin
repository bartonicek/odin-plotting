package factor

import "base:runtime"
import "core:slice"

FactorSurjection :: struct {
	cardinality: int,
	indices: []int,
	data: struct {labels: []string }
}

from :: proc(
	values: []string,
	allocator := context.allocator,
) -> (
	factor: FactorSurjection,
	err: runtime.Allocator_Error,
) #optional_allocator_error {
	labels := make([dynamic]string, 0, len(values), allocator) or_return
	defer if err != nil do delete(labels)

	indices := make([]int, len(values), allocator) or_return
	defer if err != nil do delete(indices, allocator)

	for value in values {
		_, found := slice.linear_search(labels[:], value)
		if !found {
			_, err = append(&labels, value)
			if err != nil do return
		}
	}

	slice.sort(labels[:])

	for value, i in values {
		index, _ := slice.binary_search(labels[:], value)
		indices[i] = index
	}

	result := FactorSurjection {
		cardinality = len(labels),
		indices = indices,
		data = {labels = labels[:]},
	}

	return result, nil
}

destroy :: proc(factor: ^FactorSurjection, allocator := context.allocator) {
	delete(factor.data.labels, allocator)
	delete(factor.indices, allocator)
	factor^ = {}
}
