# Character production bible v0.1 — two independent visual scales

**Status:** working production specification, **not** approved character design. Existing approved source supports four primary cast roles and a small number of possible specialist cameos. Specific sprite frame counts and supplementary emotions below are production proposals. Maintain identity across VN and map representations; do not resize VN portraits to create chibi sprites.

## Universal two-scale requirement

**VN:** full normal/anime proportions; transparent full/three-quarter-body layered presentation, face/blink/mouth overlays; master character-sheet front, back and 3/4 reference, identity/outfit/color IDs, detachable prop and post-reveal FX layers. Face expression overlays should not redraw entire pose.

**Map:** independently designed mildly-chibi reduced-proportion character (proposal: ~3.5–4.5 heads vs VN ~6–7.5), same visual signature/outfit and hair silhouette. Render at actual on-map screen size, compare foot contact with room geometry. No photoreal/pixel-art inconsistency.

**Map navigation:** authored graph means animation families can be shared: down/up/side-walk with flip only if asymmetry permits, idle, turn, interact. Door is permanently open after unlock; no repeated door opening clip. Other cast map walkers only if actually staged during the first season; static anchored NPC + VN presentation is acceptable for short specialist scenes.

**Expression layers:** neutral face, eyes/brows/mouth, optional blink and talking cycles. Show no supernatural identifier before the approved reveal chapter. Reveal overlays must be independently switchable via story flags.

## RM-CHAR-EVELYN — наследница, 26–30 предварительно

**Identity notes (approved/proposed as in Stage 1):** Длинный жилет или пальто; выразительная прядь; аккуратный городской силуэт; рабочий фартук — съёмный overlay.
**VN poses (proposed expansion):** neutral,inspect,gesture,hold_document,arms_folded,working_apron.
**VN emotions:** neutral,skeptical,curious,amused,warm,astonished,determined,concerned.
**VN reference angles:** front,three_quarter_left,three_quarter_right.
**Map mildly-chibi animation clips:** idle,walk_down,walk_up,walk_side_L,walk_side_R,turn_to_target,inspect,reach,carry_small,enter_portal,stop.
**Variants:** neutral/pre-reveal by default; post-reveal FX only when corresponding story flags and chapter gates permit; outfits should share body/rig and support prop swaps.

## RM-CHAR-ADA — домработница, выглядит 60+, фактически призрак

**Identity notes (approved/proposed as in Stage 1):** Строгая причёска, ключи, аккуратный фартук; ДО раскрытия полностью человеческий облик.
**VN poses (proposed expansion):** neutral,keys,point,arms_folded,gentle_gesture.
**VN emotions:** neutral,dry_amused,stern,warm,concerned,regretful,surprised.
**VN reference angles:** front,three_quarter_left,three_quarter_right.
**Map mildly-chibi animation clips:** idle,walk_down,walk_up,walk_side_L,walk_side_R,turn,point,keys_idle,ghost_hover_after_reveal.
**Variants:** neutral/pre-reveal by default; post-reveal FX only when corresponding story flags and chapter gates permit; outfits should share body/rig and support prop swaps.

## RM-CHAR-LUCAS — нотариус, выглядит 35–45, вампир

**Identity notes (approved/proposed as in Stage 1):** Официальный костюм/очки, папка документов; клыки ТОЛЬКО после сюжетного reveal.
**VN poses (proposed expansion):** neutral,hold_folder,adjust_glasses,explain.
**VN emotions:** neutral,formal,polite_smile,sheepish,serious,warm,surprised.
**VN reference angles:** front,three_quarter_left,three_quarter_right.
**Map mildly-chibi animation clips:** idle,walk_down,walk_up,walk_side_L,walk_side_R,turn,folder_offer,glasses_adjust.
**Variants:** neutral/pre-reveal by default; post-reveal FX only when corresponding story flags and chapter gates permit; outfits should share body/rig and support prop swaps.

## RM-CHAR-ROWAN — садовник 25–35, оборотень, живёт отдельно

**Identity notes (approved/proposed as in Stage 1):** Рабочий жилет, крепкий практичный силуэт; волчьи признаки только после раскрытия.
**VN poses (proposed expansion):** neutral,hold_plant,crouch,point_garden.
**VN emotions:** neutral,witty,happy,concerned,hurt,nostalgic,focused.
**VN reference angles:** front,three_quarter_left,three_quarter_right.
**Map mildly-chibi animation clips:** idle,walk_down,walk_up,walk_side_L,walk_side_R,turn,plant_inspect,kneel,carry_pot.
**Variants:** neutral/pre-reveal by default; post-reveal FX only when corresponding story flags and chapter gates permit; outfits should share body/rig and support prop swaps.

## Episodic specialists (not automatically full-asset characters)

- Plumber/electrician/glazier: required as *professional functions*, but identity, number of actors and final NPC character IDs are **not canonically approved**. First use can be service vignette + tool insert + silhouette/VO. Avoid generating a full VN/map pair until scene-by-scene needs prove reuse.
- Clockmaker: specialist for hall clock. Similar minimal treatment; do not assume same person as plumber or electrician.
- Food courier: delivery bag, phone notification or offscreen cue; no character sheet needed.

## Acceptance per character

1. One accepted shared identity reference with front/3/4/back, height and outfit swatches; unchanged accessories and silhouette across representations.
2. VN: neutral + selected emotions and poses, alpha edges, correct hand/prop layers, blink/talk interpolation and compatibility with text UI.
3. Map: real screen-size sheet, ground-contact origin, idle/walk orientation, no foot slide, valid travel speeds and frame bounds.
4. Evaluate in actual Hall/Corridor/Bedroom UI before full batch. No canonical art has yet been accepted.
