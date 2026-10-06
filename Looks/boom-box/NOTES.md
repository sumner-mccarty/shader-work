# Boom Box '86 (lit)

Intent: chrome-and-black portable stereo. Brushed-chrome faceplate (Metal) on a black moulded body, round
perforated speaker-grille wells (Inset/Socket, Perforated, px-locked 200), square piano keys in a chrome bezel
that light red / yellow / VU green, black knurled fader caps, ribbed black knobs with a chrome cap and red
pointer dot. VU-green value arcs. Light mode: silver-grey plastic chassis; grille, keys, knobs unchanged.

## Round 1
First sheet. Identity good (grille + chrome). Problems: keys read as capsules, not chunky squares
(corner param is squareness: 0.2 -> 0.7); light-mode grille was pale with loud holes and ate its own print.
## Round 2
Keys now square and chunky. Grille holes enlarged (p1 0.55, intensity 0.7). Light mode keeps the dark
speaker cloth (hardware, not chassis). printcheck found 5 low app-print pairs in light mode (chrome label,
tracks text/strip): added dark chrome/tracks overrides -> 0 pairs under 3:1.
## Round 3
Family contact sheet: only Street Wall is also grey, but it is flat/neon-spray; Boom Box is the only
chrome+perforated lit look. knob.small checked at 30x30: arc and red dot readable.

## Rubric
Identity: strong. Cohesion: one shadow contract, one black/chrome world. Legibility: values distinguishable
at 30 px (arc green on black). Craft: no wedges, lip 0, grille pixel-locked. States: hover/pressed/disabled/
active differ. Fidelity: grille + keys present.
Known issues: only red, yellow, green caps are lit-state colours (the kit ties ON colours to ACCENT/SOLO/LAMP
tokens; blue appears only on scroll handles); resting keys are black, not coloured; dark knob skirt is dark
on a dark grille so the chrome cap carries the knob; Perforated reads as dark dimples more than see-through holes.

## Revision round (critic: REVISE)
Looked at rack-dark, rack-light, a 6x zoom of fader/pads and knob.small at 30x30 (0%, 40%, Disabled).
- Keys: chunky near-square caps (corner 0.84), chrome ring halved (bevel 0.1), deep dome, glossy saturated caps.
  The kit paints every key from BODY, so the spec swaps in `BoomLit(Lit)` (assigned to LOOK.kit) that recolours
  per slot: Button blue, Chip green, Accent red, ToggleBtn red / Solo yellow / Lamp green (rest = dark tint of
  the cap, Active = full colour). Hover now +22% white and emissive 0.12, clearly different from Normal.
- Pads: same glossy caps, bevel 0.07, PAD_TINT 1.0, and the SAME shadow contract as the keys.
- Chassis: dark = gunmetal brushed Face + carbon-fibre black Back + silver stitch trim; light = silver-grey
  plastic with fine px-locked grain and a mid-grey silver-mesh grille. Controls pinned identical across modes.
- Light caption on the grille now dark-on-silver; ink near-black (0B0D10). Dark ink light on gunmetal.
- Blue scroll/fader removed (silver). Fader cap wider (0.44) with a 3-band ridge gradient and chrome edge.
- Fill: Back is carbon fibre, status strip sits on the grille.
Known issues: light-mode pads still read a little duller and keep a dark chamfer ring (the light rig's top-lit
chamfer; an edge override tinted it blue, so reverted); pad colours are app row colours so I can't force their hue.
At 30 px, 0% vs Disabled knob differ mainly by the lighter arc track and dimmed cap, a small difference.

## Revision round 2 (last)
Looked at final rack-dark / rack-light and knob.small at 30x30 (0% and 40%, 6x zoom).
- Light mode no longer recolours caps: the "light pads pastel" was the sheet using a different track theme
  (Rosewater) per mode, plus a brighter light rig. Both modes now use the Starfield rows and the dark rig, so
  keys, pads, knobs and fader caps render identically; only plates change (and AMB_PLATE/plate_amb tune them).
- Caps by role: Button blue, Chip/Lamp green, Accent/Toggle red #D82A2A, Solo yellow. Rest = ~80% value,
  Active = lit brighter + emissive. Pad Pressed = pushed in, no glow; Latched = glow + white ring (distinct).
- Keys: corner 0.95, bevel 0.13 / depth 1.0, shadow cast 0.34 blur 1.2 for keys and pads alike.
- Chrome: plate trim is now a 2.2 px chrome-gradient border (replaces the flat white line); finer Metal grain.
  Light Face = cool mid-silver #8C929A; dark keeps the gunmetal chassis.
- Knobs: satin-chrome cap, black knurled skirt, white needle (`_Nub` rectangle from cap to arc) replacing the red
  dot, dark solid disc behind every knob, brighter 0% arc track. Fader caps ridged with chrome ridge lines.
- Light grille: lighter silver mesh with faint holes (0.22) and near-black ink, so grille print passes printcheck.
Known issues: brushing on the plates still reads a little streaky/noisy at 1:1; key footprints are fixed by the
layouts so Button/Accent remain wide (shape cannot change aspect); trim gradient is a border band, not true
geometry; the dark Face is gunmetal so the "mid-silver chrome face" lives in light mode only.

## Factory verdict — REJECTED after 2 revision rounds (2026-10-06)

Final critic (fresh, Opus): identity 8, one-material-story 7, legibility 7, craft 6, states 6, light-mode 5, theme-fidelity 7 -> REVISE.
Unapplied fixes:
1. Light mode is not a new chassis: light Face/Back is the same mid-grey brushed metal as dark (only gutter/grille lighten). Make it pale silver-grey plastic (#C9CCD1-#D8DADE, smooth, low grain), chrome only on bezels/trim; lighten light grille base so holes read dark-on-silver.
2. Dark face is uniform mid-grey with blotchy wavy brush smears: darken to ~#1C1D20, keep bright chrome for bezels/pad frames/slider caps/display surround; finer horizontal px-locked hairline brushing.
3. Pad rows red/green/orange, no yellow/blue (brief: red/yellow/blue/green); Pad Normal/Hover/Pressed nearly identical (Hover lift, Pressed sink); Button Pressed should darken more and lose drop shadow; dark ScrollTrack/Fader track nearly invisible; pad-frame shadows heavier than buttons' (two heights).
Strengths: perforated grille wells land as the signature; chunky square keys; ridged slider caps; knob.small readable at 30 px; only neutral grey/chrome look in the family.
