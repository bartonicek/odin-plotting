package expanse

import "base:runtime"
import "core:slice"

import "../utils"

Values :: union {
	[]f64,
	[]string,
}

Expanse :: union {
	ExpanseContinuous,
	ExpansePoint,
	ExpanseBand,
}

continuous :: proc(min: f64, max: f64, allocator := context.allocator) -> ExpanseContinuous {
	return ExpanseContinuous{min, max}
}

point :: proc(labels: []string, allocator := context.allocator) -> ExpansePoint {
	return ExpansePoint{slice.clone(labels, allocator)}
}

band :: proc(
	labels: []string,
	widths: []f64 = nil,
	allocator := context.allocator,
	loc := #caller_location,
) -> ExpanseBand {
	expanse := ExpanseBand {
		labels = slice.clone(labels, allocator),
		widths = make([]f64, len(labels), allocator),
	}
	if widths == nil {
		slice.fill(expanse.widths, 1)
		expanse.total_width = f64(len(labels))
	} else {
		set_widths(&expanse, widths, loc)
	}
	return expanse
}

set_labels :: proc{set_labels_point, set_labels_band}

normalize :: proc(expanse: ^Expanse, result: Values, input: Values) {
	switch &exp in expanse {
	case ExpanseContinuous:
		res := utils.unwrap_or_panic([]f64, result)
		inp := utils.unwrap_or_panic([]f64, input)
		normalize_continuous(&exp, res, inp)
	case ExpansePoint:
		res := utils.unwrap_or_panic([]f64, result)
		inp := utils.unwrap_or_panic([]string, input)
		normalize_point(&exp, res, inp)
	case ExpanseBand:
		res := utils.unwrap_or_panic([]f64, result)
		inp := utils.unwrap_or_panic([]string, input)
		normalize_band(&exp, res, inp)
	case:
		panic("normalize: expanse has no variant set")
	}
}

unnormalize :: proc(expanse: ^Expanse, result: Values, input: Values) {
	switch &exp in expanse {
	case ExpanseContinuous:
		res := utils.unwrap_or_panic([]f64, result)
		inp := utils.unwrap_or_panic([]f64, input)
		unnormalize_continuous(&exp, res, inp)
	case ExpansePoint:
		res := utils.unwrap_or_panic([]string, result)
		inp := utils.unwrap_or_panic([]f64, input)
		unnormalize_point(&exp, res, inp)
	case ExpanseBand:
		res := utils.unwrap_or_panic([]string, result)
		inp := utils.unwrap_or_panic([]f64, input)
		unnormalize_band(&exp, res, inp)
	case:
		panic("unnormalize: expanse has no variant set")
	}
}

// Each variant trains from its own data type, so a mismatch is a caller bug.
train :: proc(
	expanse: ^Expanse,
	values: Values,
	allocator := context.allocator,
	loc := #caller_location,
) -> runtime.Allocator_Error {
	switch &exp in expanse {
	case ExpanseContinuous:
		vals := utils.unwrap_or_panic([]f64, values, loc)
		train_continuous(&exp, vals)
		return nil
	case ExpansePoint:
		vals := utils.unwrap_or_panic([]string, values, loc)
		return train_point(&exp, vals, allocator)
	case ExpanseBand:
		vals := utils.unwrap_or_panic([]string, values, loc)
		return train_band(&exp, vals, allocator)
	case:
		panic("train: expanse has no variant set", loc)
	}
}

destroy :: proc(expanse: ^Expanse, allocator := context.allocator, loc := #caller_location) {
	switch &exp in expanse {
	case ExpanseContinuous:
		destroy_continuous(&exp, allocator)
	case ExpansePoint:
		destroy_point(&exp, allocator)
	case ExpanseBand:
		destroy_band(&exp, allocator)
	case:
		panic("destroy: expanse has no variant set", loc)
	}
}
