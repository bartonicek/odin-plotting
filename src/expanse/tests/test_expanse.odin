package tests

import "core:testing"

import expanse ".."

@(test)
test_destroy_switches_over_variant :: proc(t: ^testing.T) {
	exp_point: expanse.Expanse = expanse.point({"A", "B"})
	exp_band: expanse.Expanse = expanse.band({"A", "B"}, {1, 3})
	exp_continuous: expanse.Expanse = expanse.continuous(0, 1)

	expanse.destroy(&exp_point)
	expanse.destroy(&exp_band)
	expanse.destroy(&exp_continuous)

	testing.expect_value(t, len(exp_point.(expanse.ExpansePoint).labels), 0)
	testing.expect_value(t, len(exp_band.(expanse.ExpanseBand).widths), 0)
	testing.expect_value(t, exp_band.(expanse.ExpanseBand).total_width, 0)
}
