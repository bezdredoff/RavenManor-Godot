shader_type canvas_item;

// Preview import material: suppress generated low-alpha background residue.
// Source RGBA is preserved; no silhouette-colored pixels are painted over.
void fragment() {
	COLOR.a *= smoothstep(0.05, 0.15, COLOR.a);
}
