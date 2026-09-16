package expanse

import "core:slice"

ExpanseContinuous :: struct {
	min: f64,
	max: f64,
}

set_min_max :: proc(expanse: ^ExpanseContinuous, min: f64, max: f64) {
	expanse.min = min
	expanse.max = max
}

normalize_continuous :: proc(expanse: ^ExpanseContinuous, result: []f64, input: []f64) {
	assert(len(result) == len(input))
	for i in 0 ..< len(input) {
		result[i] = (input[i] - expanse.min) / (expanse.max - expanse.min)
	}
}

unnormalize_continuous :: proc(expanse: ^ExpanseContinuous, result: []f64, input: []f64) {
	assert(len(result) == len(input))
	for i in 0 ..< len(input) {
		result[i] = input[i] * (expanse.max - expanse.min) + expanse.min
	}
}

train_continuous :: proc(expanse: ^ExpanseContinuous, values: []f64) {
	assert(len(values) > 0, "cannot train a continuous expanse on no data")
	min, max, _ := slice.min_max(values)
	set_min_max(expanse, min, max)
}

destroy_continuous :: proc(expanse: ^ExpanseContinuous, allocator := context.allocator) {
	expanse^ = {}
}
