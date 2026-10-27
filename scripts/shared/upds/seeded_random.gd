extends RefCounted

# Mirrors the project's version-1 32-bit random stream used by SeededRandom.ts.
var _state: int


func _init(seed_value: int) -> void:
	_state = seed_value & 0xffffffff


func next_float() -> float:
	_state = (_state + 0x6d2b79f5) & 0xffffffff
	var result := _state
	result = ((result ^ (result >> 15)) * (result | 1)) & 0xffffffff
	var mixed := ((result ^ (result >> 7)) * (result | 61)) & 0xffffffff
	result = (result ^ ((_u32_add(result, mixed)))) & 0xffffffff
	result = (result ^ (result >> 14)) & 0xffffffff
	return float(result) / 4294967296.0


func index(size: int) -> int:
	return int(next_float() * size)


func _u32_add(first: int, second: int) -> int:
	return (first + second) & 0xffffffff
