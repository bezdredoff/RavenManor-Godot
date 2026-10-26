# Raven Manor — narrative ↔ gameplay integration

**Runtime narrative sync:** 2026-10-26. This document captures the latest product-owner story decisions discussed on 2026-10-24–26 and maps them onto the existing Godot IDs and systems. It does not rename save IDs or silently rewrite historical Stage 1/2 source documents.

## Canon premise

Evelyn Raven is the last heir of Raven Manor. She left the manor and the town many years ago. An unexpected inheritance letter brings her back to settle the estate and understand what she has inherited.

The supernatural is not new to Evelyn's childhood, but it is no longer available to her as reliable knowledge. The current world rule is:

- the longer a person remains away from the town, the more memories connected to its supernatural life fade;
- returning to the town/manor can restore those memories gradually and in fragments;
- the cause of this effect is a long-term mystery, not an answer delivered in the opening chapter.

The tone is cozy supernatural mystery, melancholy and eccentric humor rather than horror. Early scenes should feel plausibly mundane even when the audience can sense that something is off.

## Early character presentation and reveal discipline

| Character | Early presentation | Canonical nature / role | Early-slice rule |
|---|---|---|---|
| Evelyn Raven | returning heir | protagonist; last Raven heir | she notices gaps and returning fragments, but does not begin with complete supernatural knowledge |
| Ada | resident housekeeper/caretaker | ghost; lives in the manor and does not eat | she must initially read as an eccentric but ordinary housekeeper; do not explicitly confirm that she is a ghost in RM-VS-01 |
| Lucas | notary handling inheritance formalities | vampire | he initially reads as an ordinary notary; no explicit vampire reveal in RM-VS-01 |
| Rowan | gardener who comes to work from outside the manor and lives elsewhere | werewolf | he initially reads as an ordinary gardener; his supernatural nature is a later reveal |

Do not use overt supernatural exposition to explain locked rooms, broken utilities or repair gates. Strange details may accumulate, but the player should be able to give them ordinary explanations early on.

## Practical first-act progression

The first playable priorities are domestic and understandable:

1. **Arrival / inheritance:** Evelyn returns, Lucas covers the legal handoff, Ada is introduced as the housekeeper.
2. **Make a bedroom usable:** the bedroom door is physically obstructed/jammed, not magically sealed. Entry is independent of bathroom restoration.
3. **Make the bathroom usable:** the player can inspect and prepare the work, but real plumbing repair is performed by a specialist.
4. **First night / delivery:** Evelyn can stay in the manor once the bedroom and bathroom are usable. Food comes by delivery while the kitchen is still unsafe/unready.
5. **Kitchen:** the next domestic expansion. Electricity and condition of the room must be checked before normal use.
6. **Garden / conservatory:** Rowan comes to inspect the outside/growing spaces; this is the next natural way to bring him into the active cast.
7. **Library/archive and deeper investigation:** season-one investigation space remains important, but its exact chapter placement relative to the kitchen/conservatory sequence is not locked by this runtime sync.

Future rooms/floors/wings remain closed for ordinary physical reasons such as unsafe structure, damaged roof/floors, incomplete utilities or electrical problems. These gates can later intersect with supernatural story, but they must not begin as arbitrary magic locks.

## What Match-3 means in fiction

Match-3 is **preparation work**, not a magical repair button. A completed level can represent:

- sorting and cleaning;
- clearing access to an object or room;
- finding useful parts, documents or clues;
- separating damaged from usable material;
- preparing an area so a specialist can perform real work.

The progression contract is therefore:

`hotspot / story need → Match-3 preparation → work points / first clear → restoration or specialist action → visible room state → story beat / clue / route`.

Hard repairs are performed by appropriate specialists. Current examples include plumbing, electrical work, staircase/structural work, clock mechanisms and conservatory glazing. The game may compress scheduling for pacing, but should not imply that Evelyn repaired specialist systems by matching tiles.

## Navigation and story state

- No free tap-to-move in the accepted slice.
- The player chooses a door, hotspot or target; Evelyn travels along authored navigation anchors.
- Story gates decide whether an edge/hotspot is available; the navigation solver does not own narrative sequencing.
- Door visuals may remain open/disappear after unlock, but the logical portal and persisted gate remain authoritative.
- Room Builder / imported room art must never silently mutate story flags, doors, rewards or save state.

## RM-VS-01 — current narrative mapping

The existing stable IDs are retained. Their current story meaning is:

| Runtime step | Stable IDs | Fictional meaning |
|---|---|---|
| Arrival | `RM-BEAT-01-01` | inheritance handoff; Evelyn, Lucas and Ada are introduced in ordinary roles; Ada points Evelyn toward making the bedroom/bathroom usable |
| Bedroom access | `RM-HS-005`, `RM-FLAG-BEDROOM-ACCESS-CLEARED`, `RM-DOOR-CORRIDOR-BEDROOM` | clear a physical obstruction/jammed bedroom route; no bathroom prerequisite |
| Bedroom preparation | `RM-LVL-001` | sort/clean the bedroom and recover useful belongings |
| Bedroom restoration | `RM-HS-002`, `RM-REST-001` | spend prepared work to make the bedroom livable |
| Bedroom beat | `RM-BEAT-01-02` | Evelyn recognizes the room more strongly than her conscious memory explains; Ada remains plausibly ordinary |
| Bathroom diagnosis | `RM-LVL-002`, `RM-BEAT-01-03` | inspect/clear damage and determine that a plumber is required |
| Bathroom preparation | `RM-LVL-003` | expose plumbing/access and find usable parts/material |
| Bathroom repair | `service.plumber_available`, `RM-REST-002` | specialist performs the real repair after the player prepares the job |
| Childhood clue | `RM-HS-004`, `RM-CLUE-01-CHILDHOOD-OBJECT` | a mundane childhood object triggers a fragment of memory; it is evidence of missing memory, not proof of a ghost/vampire/werewolf |
| First night | `RM-BEAT-01-04` | bedroom and bathroom are usable; food delivery substitutes for the still-unready kitchen; memory begins returning in fragments |
| Slice hook | `RM-BEAT-01-05` | next morning points toward the kitchen and Rowan's garden/conservatory visit while the larger memory mystery remains unresolved |

The current 2/2/2 first-clear rewards and 2/4 restoration costs remain an engineering balance contract. This sync changes narrative meaning and presentation, not the save schema or economy.

## Reveal rules for the slice

By the end of RM-VS-01 the player should know:

- Evelyn came back because of an inheritance and intends to stay, at least temporarily;
- she remembers the manor and town incompletely;
- memories can return after her return;
- Ada, Lucas and Rowan have clear ordinary social roles;
- the manor's practical condition creates believable restoration goals;
- there is a personal childhood clue worth investigating.

The player should **not** yet receive an explicit confirmation that Ada is a ghost, Lucas a vampire or Rowan a werewolf, nor the explanation for the town's memory effect.

## Data/runtime files

- `data/raven/season1_narrative.json` — machine-readable mirror of this sync.
- `data/raven/rm_vs_01_content.json` — playable prototype text and Match-3 fiction.
- `scripts/raven/raven_slice_director.gd` — ordering and state gates.
- `scripts/raven/raven_vn_player.gd` — supports per-line speakers so scenes can contain actual character exchanges.
- `manor_greybox_graph.json` and `season1_world_map.json` remain geometry/navigation data; they do not own story order.

## Open narrative work

This sync intentionally does not invent the cause of the memory effect, exact supernatural reveal scenes, final dialogue polish, romance/relationship arcs, or the exact position of the library/archive chapter. Those require explicit story approval and should then be added with stable IDs rather than hidden in room-art or navigation files.
