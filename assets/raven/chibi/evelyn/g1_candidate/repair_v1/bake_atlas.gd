extends SceneTree

## Deterministic import normalization of the retained imagegen source, no repaint.
const DIR := "res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/"

func _initialize() -> void:
	var source := Image.new()
	assert(source.load_png_from_buffer(FileAccess.get_file_as_bytes(DIR + "evelyn_walk_source.png")) == OK)
	assert(source.get_size() == Vector2i(1024, 1536))
	source.convert(Image.FORMAT_RGBA8)
	# Quantized smoothstep, using ONLY integers: portable across libm/SIMD.
	# RGB is untouched for retained pixels; zero-alpha RGB is cleared.
	var pixels := source.get_data()
	for index in range(0, pixels.size(), 4):
		var alpha := int(pixels[index + 3])
		if alpha <= 32:
			alpha = 0
		elif alpha < 64:
			var t := alpha - 32
			alpha = (alpha * t * t * (96 - 2 * t) + 16384) / 32768
		pixels[index + 3] = alpha
		if alpha == 0:
			pixels[index] = 0
			pixels[index + 1] = 0
			pixels[index + 2] = 0
	source = Image.create_from_data(1024, 1536, false, Image.FORMAT_RGBA8, pixels)
	var atlas := Image.create(1024, 1536, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var measurements: Array = []
	for row in range(3):
		for column in range(4):
			var cell := source.get_region(Rect2i(column * 256, row * 512, 256, 512))
			var bounds := _bounds(cell)
			assert(bounds.position.x > 0 and bounds.end.x < 256)
			assert(bounds.position.y > 0 and bounds.end.y < 512)
			# Head center is stable across arm/leg poses; never center on stride.
			var centers: Array[float] = []
			for y in range(bounds.position.y + 10, bounds.position.y + 80):
				var left := 256
				var right := 0
				for x in range(256):
					if cell.get_pixel(x, y).a > 0.5:
						left = mini(left, x)
						right = maxi(right, x + 1)
				if left < right:
					centers.append((left + right) * 0.5)
			centers.sort()
			var head_x := centers[centers.size() / 2]
			var size := Vector2i((256 * 448 + bounds.size.y / 2) / bounds.size.y, (512 * 448 + bounds.size.y / 2) / bounds.size.y)
			cell = _resize_rgba8(cell, size)
			var normalized_bounds := _bounds(cell)
			var at := Vector2i(128 - (int(head_x * 2) * size.x + 256) / 512, 480 - normalized_bounds.end.y)
			atlas.blit_rect(cell, Rect2i(Vector2i.ZERO, size), Vector2i(column * 256, row * 512) + at)
			measurements.append({"row": row, "column": column, "sourceBounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "sourceHeadCenter": head_x, "bakedSize": [size.x, size.y], "placement": [at.x, at.y]})
	if OS.get_cmdline_user_args().has("--check"):
		var expected := Image.new()
		assert(expected.load_png_from_buffer(FileAccess.get_file_as_bytes(DIR + "evelyn_walk.png")) == OK)
		assert(atlas.get_data() == expected.get_data(), "Baked pixels drift from retained generation source")
		var manifest = JSON.parse_string(FileAccess.get_file_as_string(DIR + "bake_manifest.json"))
		assert(manifest.sourceSha256 == FileAccess.get_sha256(DIR + "evelyn_walk_source.png"))
		assert(manifest.outputSha256 == FileAccess.get_sha256(DIR + "evelyn_walk.png"))
		print("PASS: retained source reproduces baked atlas pixels and hashes")
		quit()
		return
	assert(atlas.save_png(DIR + "evelyn_walk.png") == OK)
	var file := FileAccess.open(DIR + "bake_manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"sourceSha256": FileAccess.get_sha256(DIR + "evelyn_walk_source.png"), "outputSha256": FileAccess.get_sha256(DIR + "evelyn_walk.png"), "engine": Engine.get_version_info().string, "alpha": "integer smoothstep 32..64; half-up rounding; quantized zero -> RGBA zero", "resampling": "integer bilinear RGBA8 pixel centers; half-up rounding; no platform floating-point resampler", "frames": measurements}, "  ") + "\n")
	print("PASS: baked clean alpha and uniform 256x512 cells; run measure_frames.py")
	quit()

func _resize_rgba8(source: Image, size: Vector2i) -> Image:
	var input := source.get_data()
	var output := PackedByteArray()
	output.resize(size.x * size.y * 4)
	var x_den := size.x * 2
	var y_den := size.y * 2
	var denominator := x_den * y_den
	for y in range(size.y):
		var y_num := (2 * y + 1) * source.get_height() - size.y
		var top := clampi(y_num / y_den, 0, source.get_height() - 1)
		var bottom := mini(top + 1, source.get_height() - 1)
		var wy := clampi(y_num - top * y_den, 0, y_den)
		for x in range(size.x):
			var x_num := (2 * x + 1) * source.get_width() - size.x
			var left := clampi(x_num / x_den, 0, source.get_width() - 1)
			var right := mini(left + 1, source.get_width() - 1)
			var wx := clampi(x_num - left * x_den, 0, x_den)
			var a := (top * source.get_width() + left) * 4
			var b := (top * source.get_width() + right) * 4
			var c := (bottom * source.get_width() + left) * 4
			var d := (bottom * source.get_width() + right) * 4
			for channel in range(4):
				var value := int(input[a + channel]) * (x_den - wx) * (y_den - wy) + int(input[b + channel]) * wx * (y_den - wy) + int(input[c + channel]) * (x_den - wx) * wy + int(input[d + channel]) * wx * wy
				output[(y * size.x + x) * 4 + channel] = (value + denominator / 2) / denominator
	return Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, output)

func _bounds(image: Image) -> Rect2i:
	var min_point := image.get_size()
	var max_point := Vector2i.ZERO
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.5:
				min_point.x = mini(min_point.x, x)
				min_point.y = mini(min_point.y, y)
				max_point.x = maxi(max_point.x, x + 1)
				max_point.y = maxi(max_point.y, y + 1)
	return Rect2i(min_point, max_point - min_point)
