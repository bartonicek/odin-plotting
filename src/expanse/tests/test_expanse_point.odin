package tests

import "base:runtime"
import "core:testing"

import expanse ".."

@(test)
test_train_point :: proc(t: ^testing.T) {
	exp: expanse.ExpansePoint
	err := expanse.train_point(&exp, []string{"B", "A", "B", "C", "A"})
	defer expanse.destroy_point(&exp)

	testing.expect_value(t, err, runtime.Allocator_Error.None)
	testing.expect_value(t, len(exp.labels), 3)
	testing.expect_value(t, exp.labels[0], "B")
	testing.expect_value(t, exp.labels[1], "A")
	testing.expect_value(t, exp.labels[2], "C")
}

@(test)
test_normalize_point_maps_to_unit_interval :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"A", "B", "C", "D"})
	defer expanse.destroy_point(&exp)
	input := []string{"A", "B", "C", "D"}
	result := make([]f64, len(input))
	defer delete(result)

	expanse.normalize_point(&exp, result, input)
	testing.expect_value(t, result[0], 0)
	testing.expect_value(t, result[1], 1.0 / 3)
	testing.expect_value(t, result[2], 2.0 / 3)
	testing.expect_value(t, result[3], 1)
}

@(test)
test_unnormalize_point_maps_to_domain :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"A", "B", "C", "D"})
	defer expanse.destroy_point(&exp)
	input := []f64{0, 1.0 / 3, 2.0 / 3, 1}
	result := make([]string, len(input))
	defer delete(result)

	expanse.unnormalize_point(&exp, result, input)
	testing.expect_value(t, result[0], "A")
	testing.expect_value(t, result[1], "B")
	testing.expect_value(t, result[2], "C")
	testing.expect_value(t, result[3], "D")
}

@(test)
test_point_round_trip :: proc(t: ^testing.T) {
	exp: expanse.ExpansePoint
	input := []string{"LO", "MID", "HI"}
	_ = expanse.train_point(&exp, input)
	defer expanse.destroy_point(&exp)

	unit := make([]f64, len(input))
	back := make([]string, len(input))
	defer delete(unit)
	defer delete(back)

	expanse.normalize_point(&exp, unit, input)
	expanse.unnormalize_point(&exp, back, unit)

	for v, i in input {
		testing.expect(t, unit[i] >= 0 && unit[i] <= 1)
		testing.expect_value(t, back[i], v)
	}
}

@(test)
test_unnormalize_point_snaps_to_nearest :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"A", "B", "C", "D"})
	defer expanse.destroy_point(&exp)
	input := []f64{0.16, 0.17, 0.49, 0.51, 0.83, 0.84}
	result := make([]string, len(input))
	defer delete(result)

	expanse.unnormalize_point(&exp, result, input)
	expected := []string{"A", "B", "B", "C", "C", "D"}
	for v, i in expected do testing.expect_value(t, result[i], v)
}

@(test)
test_unnormalize_point_clamps :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"A", "B", "C", "D"})
	defer expanse.destroy_point(&exp)
	input := []f64{-2, -0.001, 1, 1.5}
	result := make([]string, len(input))
	defer delete(result)

	expanse.unnormalize_point(&exp, result, input)
	testing.expect_value(t, result[0], "A")
	testing.expect_value(t, result[1], "A")
	testing.expect_value(t, result[2], "D")
	testing.expect_value(t, result[3], "D")
}

@(test)
test_point_single_label :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"ONLY"})
	defer expanse.destroy_point(&exp)
	unit := make([]f64, 1)
	back := make([]string, 1)
	defer delete(unit)
	defer delete(back)

	expanse.normalize_point(&exp, unit, []string{"ONLY"})
	testing.expect_value(t, unit[0], 0.5)

	expanse.unnormalize_point(&exp, back, unit)
	testing.expect_value(t, back[0], "ONLY")
}

@(test)
test_train_point_replaces_existing :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"X", "Y", "Z"})
	defer expanse.destroy_point(&exp)

	_ = expanse.train_point(&exp, []string{"A", "B", "A"})
	testing.expect_value(t, len(exp.labels), 2)
	testing.expect_value(t, exp.labels[0], "A")
	testing.expect_value(t, exp.labels[1], "B")
}

@(test)
test_set_labels_point :: proc(t: ^testing.T) {
	exp := expanse.point([]string{"X", "Y", "Z"})
	defer expanse.destroy_point(&exp)

	err := expanse.set_labels(&exp, []string{"A", "B"})
	testing.expect_value(t, err, runtime.Allocator_Error.None)
	testing.expect_value(t, len(exp.labels), 2)
	testing.expect_value(t, exp.labels[0], "A")
	testing.expect_value(t, exp.labels[1], "B")

	result := make([]f64, 2)
	defer delete(result)
	expanse.normalize_point(&exp, result, []string{"A", "B"})
	testing.expect_value(t, result[0], 0)
	testing.expect_value(t, result[1], 1)
}
