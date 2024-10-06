# gdlint: disable=function-name

extends Node


func state(x) -> ReactiveProperty:
	return ReactiveProperty.new(x)


func derived1(p: ReadOnlyReactiveProperty, fn: Callable) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed1(p, fn)


func derived2(
	p1: ReadOnlyReactiveProperty, p2: ReadOnlyReactiveProperty, fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed2(p1, p2, fn)


func derived3(
	p1: ReadOnlyReactiveProperty,
	p2: ReadOnlyReactiveProperty,
	p3: ReadOnlyReactiveProperty,
	fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed3(p1, p2, p3, fn)


func derived4(
	p1: ReadOnlyReactiveProperty,
	p2: ReadOnlyReactiveProperty,
	p3: ReadOnlyReactiveProperty,
	p4: ReadOnlyReactiveProperty,
	fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed4(p1, p2, p3, p4, fn)


func derived5(
	p1: ReadOnlyReactiveProperty,
	p2: ReadOnlyReactiveProperty,
	p3: ReadOnlyReactiveProperty,
	p4: ReadOnlyReactiveProperty,
	p5: ReadOnlyReactiveProperty,
	fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed5(p1, p2, p3, p4, p5, fn)


func derived6(
	p1: ReadOnlyReactiveProperty,
	p2: ReadOnlyReactiveProperty,
	p3: ReadOnlyReactiveProperty,
	p4: ReadOnlyReactiveProperty,
	p5: ReadOnlyReactiveProperty,
	p6: ReadOnlyReactiveProperty,
	fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed6(p1, p2, p3, p4, p5, p6, fn)


func derived7(
	p1: ReadOnlyReactiveProperty,
	p2: ReadOnlyReactiveProperty,
	p3: ReadOnlyReactiveProperty,
	p4: ReadOnlyReactiveProperty,
	p5: ReadOnlyReactiveProperty,
	p6: ReadOnlyReactiveProperty,
	p7: ReadOnlyReactiveProperty,
	fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed7(p1, p2, p3, p4, p5, p6, p7, fn)


func derived8(
	p1: ReadOnlyReactiveProperty,
	p2: ReadOnlyReactiveProperty,
	p3: ReadOnlyReactiveProperty,
	p4: ReadOnlyReactiveProperty,
	p5: ReadOnlyReactiveProperty,
	p6: ReadOnlyReactiveProperty,
	p7: ReadOnlyReactiveProperty,
	p8: ReadOnlyReactiveProperty,
	fn: Callable
) -> ReadOnlyReactiveProperty:
	return ReactiveProperty.Computed8(p1, p2, p3, p4, p5, p6, p7, p8, fn)
