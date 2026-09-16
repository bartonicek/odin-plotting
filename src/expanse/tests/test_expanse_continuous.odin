package tests

import "core:testing"

import expanse ".."


@(test)
test_train_continuous :: proc(t: ^testing.T) {
	exp: expanse.ExpanseContinuous
	expanse.train_continuous(&exp, []f64{3, -1, 7, 2})
	defer expanse.destroy_continuous(&exp)
	testing.expect_value(t, exp.min, -1)
	testing.expect_value(t, exp.max, 7)
}

@(test)
test_normalize_continuous_maps_to_unit_interval :: proc(t: ^testing.T) {
	exp := expanse.continuous(1, 10)
	defer expanse.destroy_continuous(&exp)
	input := []f64{1, 2, 5.5, 9, 10}
	result := make([]f64, len(input))
	defer delete(result)

	expanse.normalize_continuous(&exp, result, input)
	testing.expect_value(t, result[0], 0)
	testing.expect_value(t, result[1], 1.0 / 9)
	testing.expect_value(t, result[2], 0.5)
	testing.expect_value(t, result[3], 8.0 / 9)
	testing.expect_value(t, result[4], 1)
}

@(test)
test_unnormalize_continuous_maps_to_domain :: proc(t: ^testing.T) {
	exp := expanse.continuous(1, 10)
	defer expanse.destroy_continuous(&exp)
	input := []f64{0, 0.25, 0.5, 1}
	result := make([]f64, len(input))
	defer delete(result)

	expanse.unnormalize_continuous(&exp, result, input)
	testing.expect_value(t, result[0], 1)
	testing.expect_value(t, result[1], 9.0 / 4 + 1)
	testing.expect_value(t, result[2], 5.5)
	testing.expect_value(t, result[3], 10)
}

@(test)
test_continuous_round_trip :: proc(t: ^testing.T) {
	exp: expanse.ExpanseContinuous
	input := []f64{-3.5, 0, 1.13, 4.875, 7.25}
	expanse.train_continuous(&exp, input)
	defer expanse.destroy_continuous(&exp)

	unit := make([]f64, len(input))
	back := make([]f64, len(input))
	defer delete(unit)
	defer delete(back)

	expanse.normalize_continuous(&exp, unit, input)
	expanse.unnormalize_continuous(&exp, back, unit)

	for v, i in input {
		testing.expect(t, unit[i] >= 0 && unit[i] <= 1, "normalized value outside [0,1]")
		testing.expect(t, abs(back[i] - v) < 1e-12, "round trip did not recover the input")
	}
}

@(test)
test_normalize_outside_domain :: proc(t: ^testing.T) {
	exp := expanse.continuous(0, 10)
	defer expanse.destroy_continuous(&exp)
	input := []f64{-5, 15}
	result := make([]f64, len(input))
	defer delete(result)

	expanse.normalize_continuous(&exp, result, input)
	testing.expect_value(t, result[0], -0.5)
	testing.expect_value(t, result[1], 1.5)
}
