# sdftoggle.shader — Design Context & Research

## Project Context

SDF-based shader UI system for an audio application (mixer + modules). Components so far: `sdfknob`, `sdfbutton`, `sdfpanel`, `sdfslider`. The goal is a single `sdftoggle.shader` that can reproduce a wide range of toggle/switch styles via shader params alone — covering skeuomorphic, neumorphic, flat utilitarian, dark/light, and cyberpunk/tron aesthetics.

All reskinning happens live via params so users can change the look of the entire UI at runtime.

---

## Hardware Toggle/Switch Taxonomy

Seven primary archetypes found in real audio equipment:

### 1. Bat Toggle (Lever Toggle)
A metal lever ("bat") that flips between positions.

**Variants:**
- 2-position (ON-OFF) — bypass, power, polarity flip
- 3-position (ON-OFF-ON or ON-ON-ON) — waveform select, EQ shelf/bell switching, signal routing
- Momentary-down — latching up, spring-return down (e.g. Joranalogue Switch 4)

**Found on:** Neve 1073/1084 (EQ type select), ARP Odyssey, Moog Minimoog (range switches), Fender/Marshall amps (channel select), 500-series modules, guitar effect pedal bypass, vintage Studer/Revox tape machines.

**SDF notes:** Core shape is a cylindrical or tapered rod (the bat) mounted in a panel hole. The bat angle encodes state. Shadow/highlight direction shifts with angle. 3-position adds a center detent.

---

### 2. Rocker Switch
Pivots about a center axis — one side goes down, the other goes up. Lower profile than a bat toggle. Can be illuminated.

**Found on:** Amplifier power switches, some mixer sections, guitar amp channel switches, consumer/prosumer gear.

**Aesthetic register:** More "domestic appliance" than bat toggle. Useful for a specific retro-modern look.

**SDF notes:** The body is a rectangle that rotates about its center. Bevel on each end shows which side is depressed. Illuminated variant adds an LED window inset into the rocker body.

---

### 3. Illuminated Pushbutton — Latching
Press to engage (stays in), press again to release. LED glow indicates state. **The canonical sound of SSL, Neve, and API mixing consoles.**

**Sub-shapes:**
- Square/rectangular — SSL 4000 mute (yellow), solo (green), phase buttons
- Round dome — Neve BCM10 modules, Roland TR-808/909 step buttons
- Oblong pill — many effects units
- Large square pad — Novation/Akai production surfaces

**Found on:** SSL 4000 E/G/J consoles, Neve 8078, API 1608, Roland TR-808, TR-909, Eurorack sequencers (Intellijel Quadrax).

**SDF notes:** Rectangular or circular face with inset bevel indicating pressed/unpressed state. LED glow is a key visual element — bloom around the face or through a translucent cap. Depressed state shifts the face inward and changes shadow direction.

---

### 4. Illuminated Pushbutton — Momentary
Springs back when released. Used for triggers. LED flashes while held or on gate logic.

**Found on:** Eurorack gate buttons, tape transport controls (play/stop/record), drum machine step triggers. Roland TR-808/909 are the iconic example — round, illuminated, physically momentary.

**SDF notes:** Same geometry as latching, but the pressed state is transient. The spring-return visual is a slightly more pronounced raised profile in the default state.

---

### 5. Stomp Switch / Footswitch
Chunky circular metal latching switch. Over-engineered for foot use. Very tactile.

**Found on:** Guitar effects pedals universally (Boss, Electro-Harmonix, MXR, etc.).

**Aesthetic register:** Strong "guitar gear" / "rugged" visual shorthand. Works well for a heavy-metal or utility industrial look.

**SDF notes:** Large circular disc with deep bevel, often with a textured rubber or knurled metal surface. The pressed state is a much more exaggerated inward travel than a studio pushbutton.

---

### 6. Slide Switch (Mini Panel Switch)
A small tab that slides left/right or up/down between discrete positions. **Looks like a miniature fader handle but has no continuous value — snaps to fixed positions.**

**Found on:** Roland Juno-60/106 (HPF on/off), Korg MS-20 (filter type), many vintage synth panels for binary mode options.

**SDF notes:** Belongs in the toggle shader, NOT the slider shader, despite visual similarity. The handle geometry is a small block or oval; the track is a shallow channel. No continuous interpolation — just hard position snapping.

---

### 7. Rotary Selector / Multi-Position Switch
A rotating control that clicks into discrete positions. Physically distinct from a continuous knob (detented, finite positions, no full rotation).

**Found on:** Guitar pickup selectors (Fender Telecaster 3-way blade, Stratocaster 5-way), vintage synth waveform selectors (Minimoog), input source selectors, EQ bandwidth switches.

**Aesthetic register:** The blade/lever style (guitar) is very different from the rotary knob style. The rotary selector reads as "authoritative choice" rather than "fine adjustment."

**SDF notes:** For a rotary selector in the toggle shader, the face can show an indicator line snapping between labeled arc positions. Visually similar to a knob but with hard detents. The blade variant is a flat lever rotating about a center post.

---

## Software / DAW Precedent

### Skeuomorphic Era (pre-2013)
Waves plugins, early UAD emulations, Slate Digital VBC — faithful bitmap reproductions of hardware switches. SSL clones had clearly rendered yellow/green illuminated buttons. Neve emulations had detailed metal toggle lever graphics.

### Flat / Functional Era
Ableton Live, Bitwig Studio — LED dot with a click zone. No physical metaphor, just "lit = on." High information density, low visual noise.

### Neumorphic (current trend)
Soft emboss/deboss. Pill-track-with-ball (same as iOS) but with subtle inset shadows for a tactile feel without explicit materials.

### Cyberpunk / Utility
Reaktor, Max/MSP aesthetic — outlined squares with stark lit/unlit contrast, often with grid lines and monospace labels.

### iOS / Web Pill Toggle
Rounded-rectangle track with a sliding ball. Not from audio hardware but so pervasive users expect it for simple on/off in modern UI. The "default" toggle shape in a flat design system.

---

## Reference Links

| Resource | URL | What to look at |
|---|---|---|
| Slate Digital VBC | https://slatedigital.com/virtual-buss-compressors/ | Illuminated round pushbutton rendering |
| Arturia V Collection | https://www.arturia.com/products/software-instruments | Per-synth-accurate bat toggle reproductions |
| Vintage Synth Explorer | https://www.vintagesynth.com | Period photos of actual hardware controls |
| ModularGrid Switch modules | https://modulargrid.net/e/tags/view/34 | Visual index of Eurorack switch styles |
| ModWiggler DIY | https://www.modwiggler.com | Eurorack panels, pushbutton/toggle variety |
| Dribbble audio plugin tag | https://dribbble.com/tags/audio-plugin | Current software UI toggle/switch design trends |
| Joranalogue Switch 4 | https://joranalogue.com/products/switch-4 | Dual-action toggle (latching + momentary) |

---

## Recommended `sdftoggle.shader` Param Design

### Primary `toggle_type` Parameter

| Value | Maps To | Notes |
|---|---|---|
| `BAT_2POS` | 2-position lever toggle | Core skeuomorphic toggle |
| `BAT_3POS` | 3-position lever toggle | Center-off or center-on; handles many radio-group cases |
| `PUSHBUTTON` | Square/round latching button | SSL/Neve style; use `face_shape` and `led_*` params |
| `ROCKER` | Rocking body | Pivot-center aesthetic |
| `PILL_SLIDE` | iOS-style track + ball | Modern flat digital |
| `SLIDE_SWITCH` | Mini panel slide tab | Juno-style binary snap; NOT a slider |
| `STOMP` | Circular footswitch | Guitar pedal aesthetic |

### Secondary Params (work across multiple types)

| Param | Type | Description |
|---|---|---|
| `positions` | int (2 or 3) | Number of discrete states; only meaningful for bat/slide/rotary |
| `led_enabled` | bool | Whether state is indicated by internal glow |
| `led_color` | vec3 | LED tint (SSL yellow = mute, green = solo, red = record, white = generic) |
| `led_intensity` | float | Bloom/glow strength |
| `face_shape` | enum | For pushbuttons: `SQUARE`, `ROUND`, `DOME`, `OBLONG` |
| `body_material` | enum | `METAL`, `PLASTIC`, `RUBBER` — affects specular/roughness |
| `pressed_depth` | float | How far the face travels on activation |
| `bevel_width` | float | Controls the 3D illusion edge |
| `panel_inset` | float | How much the switch body is recessed into the panel |

### State Params

| Param | Type | Description |
|---|---|---|
| `state` | float (0..1 or 0..2) | Current position; drives all visual state |
| `state_anim_t` | float (0..1) | Normalized transition progress for animated snapping |

---

## Radio Group Strategy

**Do not build a separate radio group component.** Radio group behavior is a layout/logic constraint, not a rendering concern. Recommended approach:

- A row of `PUSHBUTTON` toggles with a "one-active" mutex at the application level = SSL EQ band selector, input source selector, etc.
- A single `BAT_3POS` toggle = waveform select, filter type, EQ mode — handles the 3-choice case in one widget.
- A single `PILL_SLIDE` with `positions = 3` = a segmented control / 3-way modern selector.

The shader does not need to know it is part of a group. The `state` param is set by the application to reflect the group's resolved active state.

---

## Aesthetic Mapping Reference

Use this as a guide when setting param combinations to achieve a target look:

| Target Style | `toggle_type` | Key Params |
|---|---|---|
| Vintage SSL console | `PUSHBUTTON` | `face_shape=SQUARE`, `led_enabled=true`, `led_color=yellow/green`, `body_material=PLASTIC` |
| Neve/API channel strip | `BAT_2POS` | `body_material=METAL`, `bevel_width=high`, `panel_inset=medium` |
| Moog/ARP synthesizer | `BAT_3POS` | `body_material=PLASTIC`, small bat, `panel_inset=low` |
| Roland TR-808 | `PUSHBUTTON` | `face_shape=ROUND`, `led_enabled=true`, `led_color=red/orange`, `body_material=PLASTIC` |
| Eurorack modular | `BAT_2POS` or `PUSHBUTTON` | Compact, `body_material=METAL`, high contrast |
| Guitar pedal | `STOMP` | `pressed_depth=high`, `body_material=METAL`, `led_enabled=true` |
| Juno/vintage synth panel | `SLIDE_SWITCH` | Low profile, `body_material=PLASTIC`, no LED |
| Modern flat DAW | `PILL_SLIDE` | `led_enabled=false`, minimal bevel |
| Neumorphic | `PILL_SLIDE` or `PUSHBUTTON` | Soft shadows, low `bevel_width`, muted `led_intensity` |
| Cyberpunk / Tron | `PUSHBUTTON` or `PILL_SLIDE` | High `led_intensity`, neon `led_color`, dark `body_material`, sharp edges |

---

## Shader Architecture — One Shader vs Variants vs Split

### The core question: what kind of branching is this?

GPUs have two categories of branching and they are not equivalent:

- **Divergent branching** — different threads in the same warp/wave take different `if` paths. Expensive. The warp has to execute both sides.
- **Uniform branching** — all threads in a draw call evaluate the same condition the same way. Near-free. The GPU evaluates the condition once and the entire warp follows one path.

`toggle_type` is a **uniform** — it is the same value for every fragment in a single toggle draw call. So the raw cost of `if (toggle_type == PUSHBUTTON)` is not the real problem. The real problems are more subtle.

---

### Why dynamic uniform branching is still not the right approach

**Register pressure / occupancy.** Even with uniform branching, the GPU compiler must allocate registers for every declared variable across all branches simultaneously. If `BAT_3POS` needs 12 intermediates and `PILL_SLIDE` needs 8 different ones, the compiled shader carries all 20 — whether or not a given branch executes. High register pressure reduces the number of warps the GPU can keep in flight, which reduces occupancy, which means the GPU stalls waiting on memory more often.

**Dead code is not guaranteed to be eliminated.** The compiler may or may not fold out unused uniform branches depending on driver and optimization tier. This is not something you can rely on.

**Permutation explosion risk.** If you later add orthogonal boolean features (`led_enabled`, `normal_map`, `emissive_mask`) alongside `toggle_type`, the number of live code paths multiplies. Seven types × 4 boolean features = 112 paths in a single shader. Compile time becomes painful and the register problem gets worse.

---

### The right approach: shader keyword variants

In Unity, `#pragma shader_feature_local` (strips unused variants at build) or `#pragma multi_compile_local` (keeps all variants) creates separate compiled shader programs per keyword combination. The compiler sees only the active variant's code — dead paths are literally not present.

```hlsl
// In sdftoggle.shader
#pragma shader_feature_local _ TOGGLE_BAT_2POS TOGGLE_BAT_3POS TOGGLE_PUSHBUTTON \
                                TOGGLE_ROCKER TOGGLE_PILL TOGGLE_SLIDE TOGGLE_STOMP
```

Each compiled variant is a tight, minimal shader. At runtime the material switches keywords — zero branching overhead, zero register waste from unused paths. The authoring experience is still one `.shader` file.

Use `shader_feature_local` (not `multi_compile_local`) for toggle_type — it strips unused variants at build time and is the right choice for material-level switches that aren't set globally.

---

### Recommended file structure

```
sdftoggle.shader                  ← single authoring file, N compiled variants
  │
  ├── sdftoggle_shared.hlsl       ← UV setup, AA, lighting model, LED bloom,
  │                                  state animation, material params
  │                                  (included by ALL variants)
  │
  ├── sdf_bat.hlsl                ← SDF geometry for BAT_2POS and BAT_3POS
  ├── sdf_pushbutton.hlsl         ← SDF geometry for PUSHBUTTON (latching + momentary)
  ├── sdf_rocker.hlsl
  ├── sdf_pill.hlsl               ← PILL_SLIDE track + ball
  ├── sdf_slide.hlsl              ← SLIDE_SWITCH panel tab
  └── sdf_stomp.hlsl
```

Each geometry file exposes a single function: `float sdf_toggle(float2 uv, ...)` gated by its keyword. The shared file calls whichever one compiled in. This also lets you develop and test each geometry in complete isolation.

---

### When to actually split into separate shaders (vs variants)

Variants cover the toggle system well. A genuine split into a separate `.shader` file is warranted when:

| Condition | Why it forces a split |
|---|---|
| Different vertex outputs needed | A 3D mesh-based bat lever would need mesh vertex data; a flat SDF quad does not. If you ever leave the SDF-on-quad model for a type, it needs its own shader. |
| Different render states / blend modes | A type needing transparency (translucent LED cap with a separate pass, glass dome) may need a different render state that can't coexist in one shader's pass list cleanly. |
| Radically different instruction budget | If one type needs raymarching or multi-bounce lighting and others are flat 2D SDF, they have fundamentally different cost profiles and shouldn't share a variant pool. |
| Completely disjoint param sets | If two types share less than ~40% of their properties, the shared param block becomes noise and a maintenance burden. |

None of these conditions apply to the seven toggle types as defined. They are all 2D SDF quads with the same lighting model, same LED bloom, same state animation. **One shader file, keyword variants, shared includes is correct for this system.**

---

### Where to draw the split line in terms of shared code

The lighting model, LED bloom, AA edge softening, UV setup, material params (`bevel_width`, `pressed_depth`, `body_material`, `panel_inset`), and state animation interpolation are **all shared** across every toggle type. Only the SDF geometry function differs. That shared proportion is well above the threshold where keyword variants are the right tool.

Rough guidance on the shared-code threshold:

| Shared amount | Right move |
|---|---|
| >70% shared | One file, keyword variants, geometry in separate includes |
| 40–70% shared | Judgment call; keyword variants still viable |
| <40% shared | Separate shaders; keep only a lighting include in common |
| Fully divergent | Separate shaders, no shared file |

---

### Instruction count thresholds to watch (desktop audio app)

| Range | Status |
|---|---|
| Under ~500 instructions per variant | Comfortable, don't worry |
| 500–1500 | Use keyword variants to keep per-variant count down |
| 1500+ | Reconsider fragment approach — LUTs, precompute, cache |

The SDF geometry for a 2D toggle is cheap (bat toggle ~30–50 instructions, pushbutton with inset bevel ~60). The lighting model will dominate. The LED bloom is the one place to watch carefully — a naive multi-sample bloom will cost more than all geometry code combined. Use an analytic SDF-based glow (soft radial falloff from the face perimeter) rather than a sampling approach.

---

### LED bloom specifically

The bloom is shared code in `sdftoggle_shared.hlsl` and runs once regardless of type. Recommended approach: compute the SDF distance to the button face, apply a smooth falloff function (e.g. `exp(-d * sharpness) * led_intensity`), and multiply by `led_color`. This is ~10 instructions and looks good. Avoid any loop-based sampling approach in a UI shader.

---

## Notes for Implementation

- **Build `sdftoggle_shared.hlsl` first** — UV setup, AA, lighting, LED bloom, state animation. Verify it before writing any geometry variant. Every type depends on it.
- The `SLIDE_SWITCH` type should share geometry logic with `sdfslider.shader` handle shapes but must live in the toggle shader — no continuous interpolation, only hard position snapping.
- The 3-position bat (`BAT_3POS`) is a first-class variant, not a special case. Center-detent position is semantically distinct from "nothing selected" in a radio group.
- LED glow in `PUSHBUTTON` uses the analytic SDF bloom in the shared file — a soft radial falloff around the face perimeter or through a translucent cap shape. Not a sampling loop.
- For the `ROCKER` type, shadow and bevel direction should flip completely between states (one side raised, one depressed) — not just a translation. The normal direction reverses.
- The bat lever in `BAT_2POS`/`BAT_3POS` benefits from an anisotropic specular highlight along the lever axis to sell the cylindrical metal look.
- Profile before splitting anything further. The metric to watch is GPU occupancy dropping below ~50% due to register pressure, not raw instruction count. Use RenderDoc or Unity's frame debugger to get actual numbers per variant before restructuring.
