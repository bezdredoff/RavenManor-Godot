extends RefCounted


static func cubic_bezier(progress: float, x1: float, y1: float, x2: float, y2: float) -> float:
	# CSS curves are sampled in x-space; invert x(t) to recover their easing value.
	var t := clampf(progress, 0.0, 1.0)
	for _iteration in 6:
		var inverse := 1.0 - t
		var x := 3.0 * inverse * inverse * t * x1 + 3.0 * inverse * t * t * x2 + t * t * t
		var derivative := 3.0 * inverse * inverse * x1 + 6.0 * inverse * t * (x2 - x1) + 3.0 * t * t * (1.0 - x2)
		if absf(derivative) < 0.00001:
			break
		t = clampf(t - (x - progress) / derivative, 0.0, 1.0)
	var final_inverse := 1.0 - t
	return 3.0 * final_inverse * final_inverse * t * y1 + 3.0 * final_inverse * t * t * y2 + t * t * t
