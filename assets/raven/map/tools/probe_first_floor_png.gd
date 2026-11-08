extends SceneTree

# Read-only diagnostic for the exact approved source; no image writes or game changes.
const SOURCE = "res://a_detailed_top_down_isometric_game_map_illustratio.png"

func _initialize() -> void:
    var img := Image.new()
    var err := img.load(SOURCE)
    if err != OK:
        printerr("RAVEN_FIRST_FLOOR_IMAGE_PROBE_ERROR|load|" + str(err))
        quit(2)
        return
    var size := img.get_size()
    var sha256 := FileAccess.get_sha256(SOURCE)
    var file := FileAccess.open(SOURCE, FileAccess.READ)
    if file == null:
        printerr("RAVEN_FIRST_FLOOR_IMAGE_PROBE_ERROR|open")
        quit(2)
        return
    var byte_length := file.get_length()
    file.close()
    print("RAVEN_FIRST_FLOOR_IMAGE_METADATA|", size.x, "|", size.y, "|", sha256, "|", byte_length)
    # Two independent source-pixel crops for an accurate door/seam audit.
    var crops := [
        {"name": "LEFT_AND_HALL", "rect": Rect2i(140, 100, 980, 780)},
        {"name": "RIGHT_AND_GARDEN", "rect": Rect2i(920, 40, 740, 800)}
    ]
    for item in crops:
        var crop_image: Image = img.get_region(item["rect"])
        var crop_jpeg: PackedByteArray = crop_image.save_jpg_to_buffer(0.84)
        print("RAVEN_FIRST_FLOOR_CROP_" + str(item["name"]) + "_BEGIN")
        print(Marshalls.raw_to_base64(crop_jpeg))
        print("RAVEN_FIRST_FLOOR_CROP_" + str(item["name"]) + "_END")
    var scale: float = minf(1.0, 1200.0 / float(maxi(size.x, size.y)))
    var tw := maxi(1, roundi(float(size.x) * scale))
    var th := maxi(1, roundi(float(size.y) * scale))
    img.resize(tw, th, Image.INTERPOLATE_LANCZOS)
    var preview := img.save_jpg_to_buffer(0.75)
    if preview.is_empty():
        printerr("RAVEN_FIRST_FLOOR_IMAGE_PROBE_ERROR|preview-empty")
        quit(2)
        return
    print("RAVEN_FIRST_FLOOR_PREVIEW_JPEG_BEGIN")
    print(Marshalls.raw_to_base64(preview))
    print("RAVEN_FIRST_FLOOR_PREVIEW_JPEG_END")
    quit()
