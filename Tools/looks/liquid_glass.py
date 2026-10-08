"""Liquid Glass — water and glass (lit). Brief: Looks/BACKLOG.md#liquid-glass.

    python Tools/looks/liquid_glass.py check | sheet | write | manifest

Signature: everything looks WET. Frosted pale-aqua glass plates, translucent (alpha ~0.85) over a
deep-teal backdrop; clear domed "droplet" keys — a darker refractive core ringed by a bright
specular rim (a RADIAL ramp, core → rim) — and glass-puck knobs with a caustic shimmer
(NoiseOrganic tinted toward light). Wetness is mostly the RIG: a cool key with a tight, strong
specular (power 64) so every dome carries a sharp hotspot. Light mode is sea-glass white; the
droplets and pucks don't change.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

AQUA = "#2FD3C4"
# A droplet: the frosted-glass preset with a radial ramp — dark refractive core, bright rim — a
# deep dome and a wide soft bevel, slightly translucent so the plate reads through it.
DROPLET = {"preset": "glass.frosted", "ramp_type": "radial", "ramp": (-0.5, -0.25, 0.2, 0.75),
           "edge": (0.95, 0.75, 0.3, 0.0), "dome": 0.6, "bevel": (0.24, 0.5, 0.9), "alpha": 0.88,
           "pattern": ("Frosted", 1.5, 0.06, 1.0, 0.5, 0.5, 0.0), "amb": 0.75}
CONTROLS = dict(                      # the glassware — identical in both modes
    BODY="#5FA6AE", MARK="#F2FFFE", MARK_DIM="#B8E3E3", DIS_MARK="#4F7C80", ON_MARK="#04282B",
    BODY_HI="#8ACBD1", BODY_LO="#3E8E98", DIS_BODY="#3B6266",
    ACCENT=AQUA, SOLO="#8FE3FF", LAMP="#B6FFF0", LAMP_OFF="#A6D9D9", HOT="#FF7A6B",
    CAP="#4FB3BB", SKIRT="#3F9AA3", NUB="#F2FFFE", VALUE="#9FFFF4", VALUE_EM=0.35, ARC_OFF="#0D3A40", TRACK="#082A2F",
    HANDLE="#9AD7DB", SCROLL="#3F7F86", SCROLL_HI=AQUA, PAD_BODY="#2F6E76", PAD_TINT=0.75,
)

LOOK = Look(
    title="Liquid Glass", style="LiquidGlass", prefix="LiquidGlass", slug="liquid-glass", cls="lit", order=11,
    status="candidate", brief="BACKLOG.md#liquid-glass",
    blurb="Water and glass. Frosted aqua plates, droplet keys, glass-puck knobs - everything looks wet.",
    tagline="frosted aqua glass, droplet keys, glass pucks — everything looks wet.",
    displays="neo",
    shape={
        "key": dict(corner=0.6, round=0.6),
        "dial": dict(skirt="Circle", cap_r=0.66, bevel=0.14, depth=0.45, smooth=1.0, dome=0.65,
                     nub=0.06, nub_dist=0.5, arc_px=3.0),
        "KnobHero": dict(ticks=0, arc_px=4.0),
        "shadow": dict(blur=2.2, cast=0.18),
    },
    material={
        # wet glass: a sheen rising to the top of every plate
        "plate": {"preset": "glass.frosted", "alpha": 0.85, "plate_ramp": (0.12, 0.3)},
        "key": DROPLET,
        "accent": dict(DROPLET, tint=AQUA),
        # a glass puck: frosted body, caustic light dancing in it (NoiseOrganic tinted toward white)
        # caustics: big soft NoiseOrganic cells ADDED as light (PatternColor Additive) on saturated
        # aqua glass, the radial ramp darkening the core like the droplets
        "cap": {"preset": "glass.frosted", "ramp_type": "radial", "ramp": (-0.35, -0.1, 0.25, 0.7),
                "pattern": ("NoiseOrganic", 22.0, 0.22, 1.2, 0.5, 0.5, 0.5),
                "tint": (1, 2, (0.3, 0.5, 0.75, 0.95)), "edge": (0.95, 0.7, 0.2, -0.1),
                "dome": 0.65, "amb": 0.8, "alpha": 0.92},
        # the skirt is aqua glass too: dark wall, a bright rim only at its outer edge
        "skirt": {"preset": "glass.frosted", "edge": (0.85, 0.1, -0.25, -0.45)},
        "handle": DROPLET,
        # pads are glass tiles too (their colour is BOUND to the row, so no ramp — the kit skips it)
        "pad": {"preset": "glass.frosted", "alpha": 0.85, "dome": 0.45, "amb": 0.8},
    },
    rig={
        # wet = tight, strong highlights: a cool key, high specular power; a faint aqua bounce from below
        "dark": {"light1": dict(pos=[-0.3, 1.6], height=1.2, color="#EAFBFF", intensity=0.8, specular=0.55,
                                specularPower=64),
                 "light2": dict(pos=[0.9, -0.4], height=0.8, color="#6FE0D8", intensity=0.18, specular=0.1,
                                specularPower=32),
                 "light3": dict(enabled=False)},
        "light": {"light1": dict(pos=[-1.5, 3.0], height=4.0, color="#F4FFFF", intensity=0.8, specular=0.35,
                                 specularPower=64),
                  "light2": dict(enabled=False), "light3": dict(enabled=False)},
    },
    modes={
        "dark": dict(
            track="Aurora", blurb="Frosted aqua glass over deep water.",
            # the backdrop is deep teal; the glass plates are pale aqua at 85% alpha, so the water
            # shows through and the chassis settles to a mid teal
            palette=dict(CONTROLS, GAP="#04252A", BACK="#2E6A70", FACE="#5E9EA4", INSET="#4C8C93", SOCKET="#47878E",
                         WELL="#03191C", SHADOW="#00161A", SHADOW_A=0.55, AMB_PLATE=0.55, WELL_EM=0.1),
            app=dict(display=dict(text="#9FFFF4", textDim="#4FA7A8", textAlt="#E8FFFD"),
                     ink=dict(faceplate="#EFFFFE", faceplateDim="#BFE6E6", inset="#EFFFFE", insetDim="#BFE6E6",
                              backplane="#EFFFFE", backplaneDim="#BFE6E6", socket="#EFFFFE", socketDim="#BFE6E6",
                              reviewBar="#EFFFFE", reviewBarDim="#BFE6E6"))),
        "light": dict(
            track="Rosewater", blurb="Sea-glass white, the same droplets.",
            palette=dict(CONTROLS, GAP="#C4E0DC", BACK="#D8ECE8", FACE="#E8F4F1", INSET="#DDEEEA", SOCKET="#DAEBE7",
                         WELL="#062A2E", SHADOW="#2E5C5E", SHADOW_A=0.32, AMB_PLATE=0.86, WELL_EM=0.1),
            app=dict(display=dict(text="#9FFFF4", textDim="#4FA7A8", textAlt="#E8FFFD"),
                     ui=dict(text="#10393C", textDim="#3F6F72", accent="#11857A"),
                     ink=dict(faceplate="#10393C", faceplateDim="#3F6F72", inset="#10393C", insetDim="#3F6F72",
                              backplane="#10393C", backplaneDim="#3F6F72", socket="#10393C", socketDim="#3F6F72",
                              reviewBar="#10393C", reviewBarDim="#3F6F72"))),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
