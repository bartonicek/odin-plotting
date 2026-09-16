package main

import "core:fmt"
import "src/expanse"
import "src/scale"

main :: proc() {
	x := []f64{1.0, 2.0, 3.0, 11.0}
	scratch := make([]f64, len(x))
	defer delete(scratch)

	// []f64 -> []f64
	exp1: expanse.Expanse = expanse.continuous(0, 11)
	exp2: expanse.Expanse = expanse.continuous(0, 500)

	scale1 := scale.new(exp1, exp2)
	result := make([]f64, len(x))
	defer delete(result)
	scale.pushforward(&scale1, result, x, scratch)
	fmt.println(result)

	// []string -> []f64
	labels: expanse.Expanse = expanse.point({"a", "b", "c", "d"})
	defer expanse.destroy(&labels)

	scale2 := scale.new(labels, exp2)
	y := []string{"a", "b", "c", "d"}
	scale.pushforward(&scale2, result, y, scratch)
	fmt.println(result)

	// []f64 -> []string
	scale3 := scale.new(exp1, labels)
	result3 := make([]string, len(x))
	defer delete(result3)
	scale.pushforward(&scale3, result3, x, scratch)
	fmt.println(result3)
}
