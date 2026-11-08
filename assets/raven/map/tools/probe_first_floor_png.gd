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
    var scale := min(1.0, 1200.0 / float(max(size.x, size.y)))
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
