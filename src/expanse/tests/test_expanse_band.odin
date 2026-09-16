package tests

import "base:runtime"
import "core:testing"

import expanse ".."

@(test)
test_train_band :: proc(t: ^testing.T) {
	exp: expanse.ExpanseBand
	err := expanse.train_band(&exp, []string{"B", "A", "B", "C", "A"})
	defer expanse.destroy_band(&exp)

	testing.expect_value(t, err, runtime.Allocator_Error.None)
	testing.expect_value(t, len(exp.labels), 3)
	testing.expect_value(t, exp.labels[0], "B")
	testing.expect_value(t, exp.labels[1], "A")
	testing.expect_value(t, exp.labels[2], "C")

	testing.expect_value(t, len(exp.widths), 3)
	for width in exp.widths do testing.expect_value(t, width, 1)
	testing.expect_value(t, exp.total_width, 3)
}

@(test)
test_normalize_band_maps_to_bin_middles :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"A", "B", "C", "D"})
	defer expanse.destroy_band(&exp)
	input := []string{"A", "B", "C", "D"}
	result := make([]f64, len(input))
	defer delete(result)

	expanse.normalize_band(&exp, result, input)
	testing.expect_value(t, result[0], 0.125)
	testing.expect_value(t, result[1], 0.375)
	testing.expect_value(t, result[2], 0.625)
	testing.expect_value(t, result[3], 0.875)
}

@(test)
test_normalize_band_variable_widths :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"A", "B", "C"}, []f64{1, 2, 1})
	defer expanse.destroy_band(&exp)
	input := []string{"A", "B", "C"}
	result := make([]f64, len(input))
	defer delete(result)

	testing.expect_value(t, exp.total_width, 4)
	expanse.normalize_band(&exp, result, input)
	testing.expect_value(t, result[0], 0.125)
	testing.expect_value(t, result[1], 0.5)
	testing.expect_value(t, result[2], 0.875)
}

@(test)
test_unnormalize_band_maps_to_domain :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"A", "B", "C", "D"})
	defer expanse.destroy_band(&exp)
	input := []f64{0.125, 0.375, 0.625, 0.875}
	result := make([]string, len(input))
	defer delete(result)

	expanse.unnormalize_band(&exp, result, input)
	testing.expect_value(t, result[0], "A")
	testing.expect_value(t, result[1], "B")
	testing.expect_value(t, result[2], "C")
	testing.expect_value(t, result[3], "D")
}

@(test)
test_unnormalize_band_covers_each_bin :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"A", "B", "C"}, []f64{1, 2, 1})
	defer expanse.destroy_band(&exp)
	input := []f64{0.01, 0.24, 0.26, 0.49, 0.51, 0.74, 0.76, 0.99}
	result := make([]string, len(input))
	defer delete(result)

	expanse.unnormalize_band(&exp, result, input)
	expected := []string{"A", "A", "B", "B", "B", "B", "C", "C"}
	for v, i in expected do testing.expect_value(t, result[i], v)
}

@(test)
test_unnormalize_band_clamps :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"A", "B", "C"}, []f64{1, 2, 1})
	defer expanse.destroy_band(&exp)
	input := []f64{-2, -0.001, 1, 1.5}
	result := make([]string, len(input))
	defer delete(result)

	expanse.unnormalize_band(&exp, result, input)
	testing.expect_value(t, result[0], "A")
	testing.expect_value(t, result[1], "A")
	testing.expect_value(t, result[2], "C")
	testing.expect_value(t, result[3], "C")
}

@(test)
test_band_round_trip :: proc(t: ^testing.T) {
	exp: expanse.ExpanseBand
	input := []string{"LO", "MID", "HI"}
	_ = expanse.train_band(&exp, input)
	defer expanse.destroy_band(&exp)
	expanse.set_widths(&exp, []f64{3, 1, 4})

	unit := make([]f64, len(input))
	back := make([]string, len(input))
	defer delete(unit)
	defer delete(back)

	expanse.normalize_band(&exp, unit, input)
	expanse.unnormalize_band(&exp, back, unit)

	for v, i in input {
		testing.expect(t, unit[i] > 0 && unit[i] < 1, "normalized value outside (0,1)")
		testing.expect_value(t, back[i], v)
	}
}

@(test)
test_set_widths_updates_total :: proc(t: ^testing.T) {
	exp: expanse.ExpanseBand
	_ = expanse.train_band(&exp, []string{"A", "B"})
	defer expanse.destroy_band(&exp)
	testing.expect_value(t, exp.total_width, 2)

	expanse.set_widths(&exp, []f64{3, 1})
	testing.expect_value(t, exp.total_width, 4)

	result := make([]f64, 2)
	defer delete(result)
	expanse.normalize_band(&exp, result, []string{"A", "B"})
	testing.expect_value(t, result[0], 0.375)
	testing.expect_value(t, result[1], 0.875)
}

@(test)
test_train_band_replaces_existing :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"X", "Y", "Z"}, []f64{5, 5, 5})
	defer expanse.destroy_band(&exp)

	_ = expanse.train_band(&exp, []string{"A", "B", "A"})
	testing.expect_value(t, len(exp.labels), 2)
	testing.expect_value(t, exp.labels[0], "A")
	testing.expect_value(t, exp.labels[1], "B")
	testing.expect_value(t, len(exp.widths), 2)
	testing.expect_value(t, exp.total_width, 2)
}

@(test)
test_set_labels_band :: proc(t: ^testing.T) {
	exp := expanse.band([]string{"X", "Y"}, []f64{3, 1})
	defer expanse.destroy_band(&exp)

	err := expanse.set_labels(&exp, []string{"A", "B", "C", "D"})
	testing.expect_value(t, err, runtime.Allocator_Error.None)
	testing.expect_value(t, len(exp.labels), 4)
	testing.expect_value(t, len(exp.widths), 4)
	testing.expect_value(t, exp.total_width, 4)
	for width in exp.widths do testing.expect_value(t, width, 1)

	result := make([]f64, 4)
	defer delete(result)
	expanse.normalize_band(&exp, result, []string{"A", "B", "C", "D"})
	testing.expect_value(t, result[0], 0.125)
	testing.expect_value(t, result[3], 0.875)
}
