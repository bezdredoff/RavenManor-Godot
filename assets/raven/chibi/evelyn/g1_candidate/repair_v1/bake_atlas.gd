extends SceneTree

## Deterministic import normalization of the retained imagegen source, no repaint.
const DIR := "res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/"

func _initialize() -> void:
	var source := Image.new()
	assert(source.load_png_from_buffer(FileAccess.get_file_as_bytes(DIR + "evelyn_walk_source.png")) == OK)
	assert(source.get_size() == Vector2i(1024, 1536))
	source.convert(Image.FORMAT_RGBA8)
	# Bake the old render-only cleanup, with a stricter zero-alpha floor.
	# RGB is untouched for retained pixels. Transparent RGB is zeroed as well.
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var color := source.get_pixel(x, y)
			color.a *= smoothstep(32.0 / 255.0, 64.0 / 255.0, color.a)
			if color.a < 1.0 / 255.0:
				color = Color.TRANSPARENT
			source.set_pixel(x, y, color)
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
			var factor := 448.0 / bounds.size.y
			var size := Vector2i(roundi(256 * factor), roundi(512 * factor))
			cell.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
			var normalized_bounds := _bounds(cell)
			var at := Vector2i(128 - roundi(head_x * size.x / 256.0), 480 - normalized_bounds.end.y)
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
	file.store_string(JSON.stringify({"sourceSha256": FileAccess.get_sha256(DIR + "evelyn_walk_source.png"), "outputSha256": FileAccess.get_sha256(DIR + "evelyn_walk.png"), "engine": Engine.get_version_info().string, "alpha": "a *= smoothstep(32/255,64/255,a); quantized zero -> RGBA zero", "frames": measurements}, "  ") + "\n")
	print("PASS: baked clean alpha and uniform 256x512 cells; run measure_frames.py")
	quit()

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
