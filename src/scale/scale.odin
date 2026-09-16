package scale

import "base:runtime"

import "../expanse"
import "../utils"

Direction :: enum {
	Unset    = 0,
	Forward  = 1,
	Backward = -1,
}

DEFAULT_ZERO :: 0
DEFAULT_ONE :: 1
DEFAULT_DIRECTION :: Direction.Forward

ScaleConfig :: struct {
	zero:      Maybe(f64),
	one:       Maybe(f64),
	direction: Maybe(Direction),
}

Scale :: struct {
	domain:    expanse.Expanse,
	codomain:  expanse.Expanse,
	zero, one: f64,
	direction: Direction,
	defaults: struct {zero, one: f64, direction: Direction}
}

new :: proc(
	domain: expanse.Expanse,
	codomain: expanse.Expanse,
	config := ScaleConfig{},
	loc := #caller_location,
) -> Scale {
	zero := config.zero.? or_else DEFAULT_ZERO
	one := config.one.? or_else DEFAULT_ONE
	direction := config.direction.? or_else DEFAULT_DIRECTION

	assert(direction != .Unset, "scale.new: direction must not be unset", loc)
	assert(zero != one, "scale.new: zero and one must differ", loc)
	return Scale{domain, codomain, zero, one, direction, {zero, one, direction}}
}

// Flips which way the domain runs along the codomain.
reverse :: proc(scale: ^Scale, loc := #caller_location) {
	switch scale.direction {
	case .Forward:
		scale.direction = .Backward
	case .Backward:
		scale.direction = .Forward
	case .Unset:
		panic("scale.reverse: direction is unset", loc)
	}
}

train_domain :: proc(
	scale: ^Scale,
	values: expanse.Values,
	allocator := context.allocator,
	loc := #caller_location,
) -> runtime.Allocator_Error {
	return expanse.train(&scale.domain, values, allocator, loc)
}

train_codomain :: proc(
	scale: ^Scale,
	values: expanse.Values,
	allocator := context.allocator,
	loc := #caller_location,
) -> runtime.Allocator_Error {
	return expanse.train(&scale.codomain, values, allocator, loc)
}

renormalize_forward :: proc(value, zero, one: f64, direction: Direction) -> f64 {
	return (1 - f64(direction)) / 2 + f64(direction) * (value * (one - zero) + zero)
}

pushforward :: proc(scale: ^Scale, result: expanse.Values, input: expanse.Values, scratch: []f64) {
	when !ODIN_DISABLE_ASSERT {
		n_input := utils.untyped_len(input)
		n_result := utils.untyped_len(result)
		assert(n_result == n_input)
		assert(len(scratch) == n_input)
	}

	expanse.normalize(&scale.domain, scratch, input)
	for i in 0 ..< len(scratch) {
		scratch[i] = renormalize_forward(scratch[i], scale.zero, scale.one, scale.direction)
	}
	expanse.unnormalize(&scale.codomain, result, scratch)
}

renormalize_backward :: proc(value, zero, one: f64, direction: Direction) -> f64 {
	return (f64(direction) * (value - (1 - f64(direction)) / 2) - zero) / (one - zero)
}

pullback :: proc(scale: ^Scale, result: expanse.Values, input: expanse.Values, scratch: []f64) {
	when !ODIN_DISABLE_ASSERT {
		n_input := utils.untyped_len(input)
		n_result := utils.untyped_len(result)
		assert(n_result == n_input)
		assert(len(scratch) == n_input)
	}

	expanse.normalize(&scale.codomain, scratch, input)
	for i in 0 ..< len(scratch) {
		scratch[i] = renormalize_backward(scratch[i], scale.zero, scale.one, scale.direction)
	}
	expanse.unnormalize(&scale.domain, result, scratch)
}

move :: proc(scale: ^Scale, amount: f64) {
	scale.zero += f64(scale.direction) * amount
	scale.one += f64(scale.direction) * amount
}

set_defaults :: proc(scale: ^Scale, defaults: ScaleConfig) {
	zero := defaults.zero.? or_else DEFAULT_ZERO
	one := defaults.one.? or_else DEFAULT_ONE
	direction := defaults.direction.? or_else DEFAULT_DIRECTION

	scale.zero = zero
	scale.one = one
	scale.direction = direction
	scale.defaults = {zero, one, direction}
}

reset :: proc(scale: ^Scale) {
	scale.zero = scale.defaults.zero
	scale.one = scale.defaults.one
	scale.direction = scale.defaults.direction
}
