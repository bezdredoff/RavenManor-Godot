# RM-GFX-WATERCOLOR-001 — VN watercolor A/B pilot

Experimental duplicate of `RM-BEAT-02-01` (Evelyn and Ada tea scene). The original `hall_tea_vn.tscn` remains untouched. The second launcher card opens `hall_tea_watercolor.tscn`, using the same dialogue, localization, sprites and layout but applying an independent Godot 4 CanvasItem shader to the background and two actors. Dialogue UI stays crisp. The duplicate overrides beat completion so it never changes the campaign save.

Shader controls: `paper_strength`, `pigment_strength`, `edge_strength`, `grain_scale`. This is a lightweight procedural watercolor approximation, **not** a physically accurate wash/bleed simulator. Screen-space grain may move relative to sprites. Test on actual mobile Web GL Compatibility before accepting style or performance.

Acceptance checklist: both cards open from GitHub Pages; original appearance unchanged; 12 lines and RU/BE/EN behave identically; both actors preserve alpha; no save mutation in the comparison; no shader compilation errors; 390x844 and tablet portrait readability; record screenshots and device FPS.

Status: candidate code only; Godot CI, Pages publication and real-device QA have not been verified in this authoring session.
