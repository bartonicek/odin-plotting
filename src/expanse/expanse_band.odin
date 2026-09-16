package expanse

import "base:runtime"
import "core:slice"

ExpanseBand :: struct {
	labels:      []string,
	widths:      []f64,
	total_width: f64,
}

set_labels_band :: proc(
	expanse: ^ExpanseBand,
	labels: []string,
	allocator := context.allocator,
) -> (
	err: runtime.Allocator_Error,
) {
	assert(len(labels) > 0, "cannot set a band expanse to no labels")

	clone := slice.clone(labels, allocator) or_return
	defer if err != nil do delete(clone, allocator)

	widths := make([]f64, len(labels), allocator) or_return
	slice.fill(widths, 1)

	delete(expanse.labels, allocator)
	delete(expanse.widths, allocator)
	expanse.labels = clone
	expanse.widths = widths
	expanse.total_width = f64(len(labels))
	return nil
}

set_widths :: proc(expanse: ^ExpanseBand, widths: []f64, loc := #caller_location) {
	assert(len(widths) == len(expanse.widths), "set_widths: need one width per label", loc)
	total: f64
	for width in widths {
		assert(width > 0, "set_widths: widths must be positive", loc)
		total += width
	}
	copy(expanse.widths, widths)
	expanse.total_width = total
}

normalize_band :: proc(expanse: ^ExpanseBand, result: []f64, input: []string) {
	assert(len(result) == len(input))
	for i in 0 ..< len(input) {
		index, found := slice.linear_search(expanse.labels, input[i])
		assert(found, "normalize: label is not present in the expanse")
		offset: f64
		for j in 0 ..< index do offset += expanse.widths[j]
		result[i] = (offset + expanse.widths[index] / 2) / expanse.total_width
	}
}

unnormalize_band :: proc(expanse: ^ExpanseBand, result: []string, input: []f64) {
	assert(len(result) == len(input))
	n := len(expanse.labels)
	for i in 0 ..< len(input) {
		position := input[i] * expanse.total_width
		index := n - 1
		edge: f64
		for j in 0 ..< n {
			edge += expanse.widths[j]
			if position < edge {
				index = j
				break
			}
		}
		result[i] = expanse.labels[index]
	}
}

train_band :: proc(
	expanse: ^ExpanseBand,
	values: []string,
	allocator := context.allocator,
) -> (
	err: runtime.Allocator_Error,
) {
	assert(len(values) > 0, "cannot train a band expanse on no data")

	labels := make([dynamic]string, 0, len(values), allocator) or_return
	defer if err != nil do delete(labels)

	for value in values {
		if _, found := slice.linear_search(labels[:], value); !found {
			_, err = append(&labels, value)
			if err != nil do return err
		}
	}

	widths := make([]f64, len(labels), allocator) or_return
	slice.fill(widths, 1)

	delete(expanse.labels, allocator)
	delete(expanse.widths, allocator)
	expanse.labels = labels[:]
	expanse.widths = widths
	expanse.total_width = f64(len(labels))
	return nil
}

destroy_band :: proc(expanse: ^ExpanseBand, allocator := context.allocator) {
	delete(expanse.labels, allocator)
	delete(expanse.widths, allocator)
	expanse^ = {}
}
