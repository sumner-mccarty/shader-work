// ShaderConstants.cs
// C# mirror of shader-side #define enums in the CG/Core .cginc files.
// These enums power [Enum(TypeName)] material property drawers in SDFKnob.shader
// and are used directly in C# via SetFloat().
//
// IMPORTANT: Values here MUST stay in sync with the matching #defines:
//   GradientType  <-> CG/Core/UIGradients.cginc  (GRADIENT_*)
//   PatternType   <-> CG/Core/UIPatterns.cginc   (PATTERN_*)
//
// An editor validator in ShaderConstantsValidator.cs will warn at load time if they drift.

// Bevel cross-section profile for CalculateShapeBevelNormal
public enum BevelProfileType
{
    Dome   = 0,  // Smooth sine-dome roll-off (default)
    Linear = 1,  // Constant-slope angled shelf
}

// Matches GRADIENT_* defines in UIGradients.cginc
public enum GradientType
{
    Linear     = 0,
    Radial     = 1,
    Angular    = 2,
    Diamond    = 3,
    Triangle   = 4,
    // RM-only bevel topology types — only meaningful for Knob Bevel Gradient in SDFKnobRM.
    // Uses the 2D SDF surface normal at the raymarched hit point.
    // normalDot=dot(normal,radialOut): +1=outer wall, 0=side, -1=back.
    // tangentialMag=|dot(normal,tangent)|: 1=pure slit side.
    BevelDepth = 5,  // Linear A(outer)→D(groove back) ramp. scale=range multiplier (1=default), offset=shift
    BevelWalls = 6,  // Zones: A=outer wall, B=side outward half, C=side inward half, D=groove/slit back
                     // scale=transition sharpness (1=soft, 5=sharp), offset shifts outer/groove threshold
}

// Matches PATTERN_* defines in UIPatterns.cginc
public enum PatternType
{
    // Surface materials (0-4)
    Plastic        = 0,
    Metal          = 1,
    RadialBrushed  = 2,
    CarbonFiber    = 3,
    Leather        = 4,
    // Brushed finishes (5-6)
    BrushedCross   = 5,
    Satin          = 6,
    // Mineral / fabric (7-10)
    Concrete       = 7,
    Fabric         = 8,
    Paper          = 9,
    Frosted        = 10,
    // Geometric (11-14)
    DiamondPlate   = 11,
    Knurled        = 12,
    HexGrid        = 13,
    Perforated     = 14,
    // Organic (15-17)
    WoodGrain      = 15,
    Marble         = 16,
    Ceramic        = 17,
    // Special (18-19)
    Circuit        = 18,
    NoiseOrganic   = 19,
}

// Knob body shape (getKnobSDF in SDFKnob.shader)
public enum KnobShapeType
{
    Circle          = 0,
    GripNubs        = 1,   // shapeScale=count, param1=width, param2=depth, param3=roundness
    Polygon         = 2,   // shapeScale=sides, param1=corner rounding, param2=edge arc, param3=arc direction
    DShaft          = 3,   // param1=cut depth, param2=edge softness, param3=corner rounding
    Star            = 4,   // shapeScale=points, param1=inner ratio, param2=tip rounding
    Squircle        = 5,   // param1=squareness (0=circle → 1=square), param2=x-squeeze
    Fluted          = 6,   // shapeScale=count, param1=depth, param2=sharpness, param3=phase offset
    Cross           = 7,   // param1=arm width, param2=arm length, param3=corner rounding
    ChickenHead     = 8,   // param1=handle length, param2=handle width, param3=blend radius
    Arrow           = 9,   // param1=head width, param2=tail width, param3=tail length
    Gear            = 10,  // shapeScale=teeth, param1=tooth height, param2=root rounding, param3=tooth width
    Skirted         = 11,  // param1=cap radius, param2=groove width, param3=groove depth  [was Teardrop]
    OvalPointer     = 12,  // param1=aspect ratio, param2=flat cut, param3=tip rounding
    MushroomCap     = 13,  // param1=cap overhang, param2=stem width, param3=stem length (rotated 90° CW)
    DaviesIndicator = 14,  // param1=slot length, param2=slot width, param3=slot rounding  [was Shield]
    ColletKnob      = 15,  // shapeScale=hub sides, param1=hub radius, param2=hub depth, param3=knurling  [was HexRound]
    RingPointer     = 16,  // param1=ring thickness, param2=tab width, param3=tab length (rotated 90° CW)
    BlobStar        = 17,  // shapeScale=points, param1=inner ratio, param2=tip rounding, param3=circle blend
    CapScrew        = 18,  // param1=slot width, param2=slot depth, param3=Phillips (0=flat / 1=cross)
    TaperDisc       = 19,  // param1=taper amount, param2=taper angle, param3=edge rounding
    FaderCap        = 20,  // param1=aspect ratio, param2=groove depth, param3=corner rounding
    FaderCapWide    = 21,  // param1=aspect ratio, param2=screw radius, param3=corner rounding
    Texture         = 100, // SDF sampled from Texture2DArray layer (_KnobShapeTexLayer)
}

// Nub indicator shape (getNubSDF in SDFKnob.shader)
public enum NubShapeType
{
    // --- Original 10 shapes ---
    Circle      = 0,   // param1: (unused)
    Rectangle   = 1,   // param1: (unused)
    RoundedRect = 2,   // param1: cornerRadius
    Ellipse     = 3,   // param1: (unused)
    Triangle    = 4,   // param1: (unused)
    Diamond     = 5,   // param1: (unused)
    Play        = 6,   // param1: (unused)
    LineV       = 7,   // param1: cornerRadius
    LineH       = 8,   // param1: cornerRadius
    Dot         = 9,   // param1: (unused)
    // --- New shapes (10–19) ---
    Arrow       = 10,  // param1: headWidthRatio [0..1], param2: tailWidthRatio [0..1]
    Star        = 11,  // param1: tipSharpness [0=fat..1=sharp], param2: pointCount [3..9 via 0..1]
    Cross       = 12,  // param1: armWidthRatio [0..1], param2: rounding [0..1]
    Heart       = 13,  // param1: (unused) scale follows width/height
    Hexagon     = 14,  // param1: (unused)
    Pentagon    = 15,  // param1: (unused)
    Rhombus     = 16,  // param1: widthStretch [0=tall..1=wide]
    Ring        = 17,  // param1: ringThickness [0=thin..1=half]
    CutDisk     = 18,  // param1: cutHeight [0=full circle..1=half cut]
    Pie         = 19,  // param1: sectorAngle [0=sliver..1=full circle]
}

// Button body shape (getButtonSDF in SDFButton.shader / SDFButtonRM.shader)
public enum ButtonShapeType
{
    Squircle   = 0,   // param1=squareness (0=circle/pill → 1=sharp rect); stretches with aspect ratio
    Polygircle = 1,   // param1=0→circle, param1>0→n-gon (3-12 sides); uniform (never stretches); param2=corner rounding
    Tab        = 2,   // param1=top corner radius (0=sharp, 1=half-circle top); rounded top, flat bottom
    Hexagon    = 3,   // Flat-top hexagon; stretches with half-extents; param1=corner rounding
    Octagon    = 4,   // Rectangle with chamfered 45° corners; stretches with half-extents; param1=corner cut amount
    Texture    = 100, // SDF sampled from Texture2DArray layer (_ButtonShapeTexLayer)
}

// Panel body shape (getPanelBodySDF in SDFPanelShapes.cginc)
public enum PanelBodyShapeType
{
    Squircle   = 0,   // param1=squareness (0=circle/pill → 1=sharp rect); stretches with aspect ratio
    Polygircle = 1,   // param1=0→circle, param1>0→n-gon (3-12 sides); uniform; param2=corner rounding
    Tab        = 2,   // param1=top corner radius; rounded top, flat bottom
    Hexagon    = 3,   // Flat-top hexagon; stretches with half-extents; param1=corner rounding
    Octagon    = 4,   // Rectangle with chamfered 45° corners; param1=corner cut amount
    Texture    = 100, // SDF sampled from Texture2DArray layer (_PanelBodyShapeTexLayer)
}

// Corner hardware drive type (pnScrewRecessSDF in CG/SDF/SDFPanelScrews.cginc).
// Shapes 4 and 5 have no drive recess at all — they are the "this is a rivet / this is a bolt"
// options, which is what most rack gear actually has in its corners.
public enum ScrewShapeType
{
    Slotted   = 0,  // One straight drive slot; _PanelScrewRotation sets its angle
    Phillips  = 1,  // Equal cross
    HexSocket = 2,  // Allen / cap screw
    Torx      = 3,  // Six-lobe star
    Dome      = 4,  // Plain domed rivet — round head, no recess
    HexHead   = 5,  // Hexagonal BOLT head outline, no recess
    Pozidriv  = 6,  // Cross plus four shorter 45° ticks
    Robertson = 7,  // Square socket
}

// Slider handle shape (getHandleSDF in SDFSliderHandleShapes.cginc)
public enum SliderHandleShapeType
{
    Capsule      = 0,  // Horizontal capsule (pill)
    Circle       = 1,  // Perfect circle
    FlatRect     = 2,  // Rounded rectangle; param1=corner radius fraction
    OvalPointer  = 3,  // Oval with pointing tip; param1=tipSharpness
    WingFader    = 4,  // Studio-fader wing shape; param1=wingWidth, param2=tipRadius
    ArrowHandle  = 5,  // Diamond/arrow pointer; param1=sharpness
    FaderCap     = 6,  // Narrow fader cap with recessed grip; param1=gripDepth
    FaderCapWide = 7,  // Wide fader cap; param1=gripDepth
    DShaft       = 8,  // D-shaft / half-cylinder; param1=flatFraction
    Squircle     = 9,  // Squircle thumb; param1=squareness
    Texture      = 100,// SDF sampled from Texture2DArray layer (_HandleShapeTexLayer)
}

// Icon indicator shape (getIconSDF in SDFButtonLayers.cginc)
public enum IconShapeType
{
    Circle      = 0,
    Rectangle   = 1,
    RoundedRect = 2,   // param1=cornerRadius
    Ellipse     = 3,
    Triangle    = 4,   // Pointing up
    Diamond     = 5,
    Play        = 6,   // Triangle pointing right
    LineV       = 7,   // param1=cornerRadius
    LineH       = 8,   // param1=cornerRadius
    Dot         = 9,
    Arrow       = 10,  // param1=headWidth, param2=tailWidth
    Star        = 11,  // param1=innerRatio, param2=pointCount
    Cross       = 12,  // param1=armWidthRatio, param2=rounding (also serves as "plus")
    Heart       = 13,
    Hexagon     = 14,
    Pentagon    = 15,
    // --- App icon set (16+, frozen 2026-07-19 — see Docs/RhythmGamePortPlan.md §4.5).
    // Unimplemented indices render as a circle placeholder (getIconSDF default case).
    Eye         = 16,  // MultiTrack row solo
    SpeakerOff  = 17,  // MultiTrack row mute
    Speaker     = 18,  // unmuted-state affordances
    Close       = 19,  // overlay/sheet close (×)
    Chevron     = 20,  // param1: 0=points right, 1=points down (pickers, disclosure)
    Grabber     = 21,  // reserved — bottom-sheet drag handle
    Search      = 22,  // reserved — search fields
    Gear        = 23,  // reserved — settings affordance
    Check       = 24,  // reserved — confirm/save
    Loop        = 25,  // reserved — transport loop toggle
    Metronome   = 26,  // reserved — transport metronome toggle
    Folder      = 27,  // reserved — load/save file buttons
    Film        = 28,  // reserved — VideoSync load video
    Power       = 29,  // IEC 5010 mark — the mixer's per-module enable lamps
    Texture     = 100, // SDF sampled from Texture2DArray layer (_IconShapeTexLayer)
}

// Outer decorative ring stroke style
public enum OuterRingStyle
{
    Solid  = 0,
    Dashed = 1,
    Dotted = 2,
}

// Outer scale-mark rendering mode
public enum OuterMarksType
{
    Lines = 0,
    Dots  = 1,
    Arcs  = 2,
    Mixed = 3,
}

// Matches PatternColorMode values used in ApplyMaterialPattern (UIPatterns.cginc)
public enum PatternColorMode
{
    Modulate = 0,   // palette color brightness-modulated by pattern strength
    Lerp     = 1,   // base color blends to palette color at strong features
    Additive = 2,   // palette color added at strong positive features
    Multiply = 3,   // palette color tints/darkens base color
}

// Matches PATTERN_COLORTYPE_* defines in UIPatterns.cginc
public enum PatternColorType
{
    Gradient = 0,   // signed range [-1,+1] → palette: negative=A, zero=mid, positive=D
    Feature  = 1,   // feature strength → palette: flat surface=A, peak feature=D
    Zones    = 2,   // repeating palette cycles — irregular coloring per feature instance
    Bands    = 3,   // sine-wave banding — rings, veins, layered patterns
}

// Toggle hardware archetypes — each type has its own bespoke shader.
// Active: SDFTogglePill.shader / SDFTogglePillRM.shader.
// Future types (Rocker, Bat, LightSwitch, etc.) each get their own shader +
// SDFToggle{Type}Shapes.cginc implementing getToggleBodySDF / getToggleTrackSDF.
public enum ToggleType
{
    Pill    = 0,  // Pill / iOS slide toggle — SDFTogglePill.shader
    // Rocker, Bat, Rotary, etc. to be added as bespoke shaders
}
