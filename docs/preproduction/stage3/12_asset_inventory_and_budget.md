# 12 — Asset inventory, reuse and budget | Stage 3 v0.1

**Distinguish measured from estimated.** Measured source counts: 24 beats, 15 hotspot records, 7 room IDs referenced in beats (including entry/overlay), 4 speaking/appearing character IDs. Character beat appearances: {'RM-CHAR-EVELYN': 24, 'RM-CHAR-LUCAS': 7, 'RM-CHAR-ADA': 10, 'RM-CHAR-ROWAN': 7}. Room beat appearances: {'RM-ROOM-ENTRY': 1, 'RM-ROOM-HALL': 5, 'RM-ROOM-BEDROOM': 2, 'RM-ROOM-BATHROOM': 1, 'RM-ROOM-KITCHEN': 5, 'RM-ROOM-ARCHIVE': 5, 'RM-ROOM-CONSERVATORY': 5}.

| Family | Target budget [PROPOSAL] | Reuse / production instruction |
|---|---|---|
| Full master painted rooms | 5 (hall, bedroom, kitchen, archive, conservatory); corridor lightweight passage | one architecture base each; do not count entry or locked wing as full room |
| Compact set | 1 bathroom | use narrow crop + object layers |
| Threshold / light environment | entry, corridor, 3–4 locked-edge silhouettes | share architectural motifs and camera |
| Room states | ruined / stabilized / restored; reveal overlay in selected rooms | 2 big visible transitions max per main room; keep base geometry fixed |
| Primary cast | 4 (Evelyn/Ada/Lucas/Rowan) | 1 canonical outfit each initially; extra phase only story motivated |
| Secondary workers | 0–2 portraits or offscreen voice | repair via sound/prop inserts first; no full-body rigger needed |
| VN pose families | 2–3 per primary character | neutral, inspect, emote; reuse head/face masks |
| Expressions | 5–7 per primary character | variations as facial overlay, not full illustration |
| Map-scale clips | 4–6 Evelyn, 2–3 each recurrent NPC | walk, idle, interact, optional turn; no 8-direction rig upfront |
| Props/clue inserts | 12–20 unique props across ~6 reusable material families | stamps, papers, clock parts, cleaning tools, gardening tools, keepsakes |
| Door states | locked/closed/opening/open/closing FSM shared; art 2–3 states each unique door family | one common hinge/open system and foreground mask system |
| Foreground masks | 1–3 per full master room, ~1 per passage | reuse doorframe/column occluders |
| Lighting | base daytime + selective evening/night, 1–2 variants per main room | shader tint where safe, custom art only with new story function |
| Effects/UI markers | 6–10 reusable cues | interact, locked, clue reveal, repair, hint, camera focus |
| New full-size art beats | <=25–35% target | favor existing background, portraits, prop inserts |
| Expensive shot reuse | >=3 contexts or downgrade | budget <=2 unique high-risk character+prop/group interactions |

## Recommended style/model bake-off

1. Evelyn stable model-sheet (front / 3-4 / portrait / small map scale), test face consistency.
2. Ada portrait neutral + expression overlay, deliberately mundane appearance before reveal.
3. Hall base ruined/stabilized composite including clock, deep door occlusion and staircase locked silhouette.
4. Narrow corridor portrait scroll + bedroom door foreground mask.
5. Bedroom bed restoration layer + height-mark clue insert.
6. Bathroom compact tap states, no precise hand-plumbing illustration.
7. Conservatory architectural perspective + foliage layers + Rowan walk sprite.
8. Clock prop close-up + letter insert with high legibility.

## Manual vs procedural / layered

- **Procedural/layered:** highlights, markers, camera pan/focus, fog/dust, particles, low-risk lighting, mask clipping, handoff dialogs.
- **Manual polish:** faces/hands, long straight architecture perspective, doorframe mask edges, legible written clues, glass and reflective metals.
- **Cut or replace:** one-off group shot, Evelyn personally rewiring house, single-use broken-window action scene, new full-room view solely for a clue.

**Risk caveat:** ranges are production targets, not measured costs or vendor estimates. No final images generated.