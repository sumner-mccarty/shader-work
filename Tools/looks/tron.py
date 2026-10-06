"""Tron Dark + Tron Light — the lookkit re-expression of Tools/design_tron.py (proof spec).

    python Tools/looks/tron.py check | write | sheet | diff [--root DIR]

Neon: Flat's unlit rules, but form comes from LIGHT TUBES on a black floor (the kit's `neon` class:
core = border band, bloom = additive edge ring, sheen = unlit bevel band). Mode-dependent weights
(tube width, bloom, plate line/halo px, the HexGrid) are palette tokens, so a mode can re-weight
the tubes without touching the shape language.
DARK  = the grid at night: thin tubes, deep navy-black glass, blue→violet with pink at the tip.
LIGHT = the same black room, tubes wide and white-hot, a big pale bloom, glass that catches it.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

LOOK = Look(
    title="Tron", style="Tron", prefix="Tron", slug="tron", cls="neon", order=3, status="shipped",
    brief="Tools/design_tron.py (shipped before the kit)",
    blurb="Unlit neon. Every edge is a light tube: a gradient core, an additive bloom, sheen on black glass.",
    tagline="unlit, non-raymarched neon tubes on black glass.",
    note="The rig (Themes/Tron.theme) has every lamp off: all the light on screen is emissive — border\n"
         "cores, additive edge blooms, arc glows.",
    displays="tron",
    shape={"dial": {"silhouette": "capped"},
           # the scroll dot is a small circle with its own tube; it shipped at pad 0.1, not RackDot's 0.252
           "Dot": {"pad": 0.1}},
    waive={"footprint:Dot": "shipped TronDark/LightDot at pad 0.1 (RackDot is 0.252), so the Tron dot draws "
                            "and hit-tests larger — reproduced as shipped; drop the override to restore RackDot's"},
    modes={
        "dark": dict(
            track="Grid", blurb="The grid at night. Neon tubes on black glass - blue, with pink at the tip.",
            palette=dict(
                # the floor: gaps are pure void, plates are navy-black glass lifted a hair at the top
                GAP="#000205", BACK="#01040A", BACK_TOP="#020812", FACE="#02060D", FACE_TOP="#07121F",
                INSET="#01040A", INSET_TOP="#030A14", SOCKET="#01040A", WELL="#000307", WELL_TOP="#01060D",
                BODY="#02070E", BODY_TOP="#081628", DIS_BODY="#02050A",
                # one tube, four stops left→right: cyan, azure, indigo, and pink only at the tip
                TUBE=("#2BE4FF", "#3D9BFF", "#6D6BFF", "#FF4FD8"), TUBE_REST=("#1597B8", "#2067B0", "#4644A8", "#A8338F"),
                TUBE_DIS=("#0A2533",) * 4, STRUCT="#0C3448", STRUCT_HI="#17597A",
                HALO=("#1FC8FF", "#2F8BFF", "#5A5CFF", "#FF3FC8"), HALO_REST=0.50, HALO_HOVER=0.80, HALO_ON=1.2,
                SHEEN="#082038", SHEEN_ON="#9FF3FF", ARC_EMIT=0.3, FACE_LINE_PX=1.5, FACE_HALO_PX=3.0,
                FACE_SHEEN=0.035, PLATE_SHEEN="#0B2A4A", GRID=0.06, LINE=1.0, BLOOM=1.0,
                MARK="#BDF5FF", MARK_DIM="#4B86A6", ON_MARK="#01060C", DIS_MARK="#1F4254",
                INK="#D8F7FF", INK_DIM="#5E93AE",
                ACCENT=("#33E6FF", "#3F8CFF"), ACCENT_HI=("#7DF1FF", "#77AEFF"), ACCENT_DIS=("#0B2C3A", "#0B2440"),
                HOT=("#FF4FB8", "#FF3F8F"), SOLO=("#33E6FF", "#3FA6FF"), LAMP=("#7FF6FF", "#33E6FF"),
                ARC_OFF="#0B2333", ARC_OFF_HI="#113348", ARC=("#2BE4FF", "#3D9BFF", "#6D6BFF", "#FF4FD8"),
                ARC_GLOW="#22C4FF", ARC_GLOW_I=0.55,
                CAP="#01050B", CAP_TOP="#0A1B2D", CAP_RING="#1A7FA5", CAP_RING_HI="#2BE4FF", NEEDLE="#E6FCFF",
                TRACK="#0A1F2E", HANDLE="#E6FCFF", HANDLE_HI="#FFFFFF",
                PAD_BODY="#02060C", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.85, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.04,
                PAD_SHEEN_TINT=0.18, SCROLL="#0E3A52", SCROLL_HI="#1D6F95"),
            app=dict(
                chrome=dict(headerBg="#01050B", headerBorder="#2067B0", tabFillBottom="#02070E", tabFillTop="#02070E",
                            tabFillActiveBottom="#061426", tabFillActiveTop="#0A1D33", iconActive="#2BE4FF",
                            meatballLit="#FF4FD8"),
                ui=dict(textFaint="#2E5468", accent="#2BE4FF", warn="#FFC93E", danger="#FF3F8F", ok="#3DFFB0"),
                surface=dict(card="#020810F5", cardEdge="#2067B0", divider="#0A2233", scrim="#000307C8"),
                display=dict(text="#7FF0FF", textDim="#2E7A94", textAlt="#FF7AD9", warn="#FF3F8F"),
                key=dict(edgeOff="#1597B8", bankEdgeOff="#0C3448", velOn="#2BE4FF"),
                pad=dict(empty="#02060C80", ringWhite="#FFFFFF4D", ringBack="#01050BE0"),
                review=dict(bar="#01050BF0", barRule="#2BE4FF22"),
                tracks=dict(backdrop="#000307", strip="#01050B", rowWithSample="#051226", rowEmpty="#020810",
                            rowNotesNoSample="#1C0A22", text="#9FDFF2", ruler="#2BE4FFB0", playhead="#FF4FD8E6",
                            recMarker="#FF3F8FDC", scrollbar="#2BE4FF26")),
        ),
        "light": dict(
            track="Grid", blurb="The Legacy cockpit: the black room, tubes blown white-hot.",
            palette=dict(
                # the same black room — glossy charcoal glass that catches the strips
                GAP="#030405", BACK="#08090B", BACK_TOP="#0F1215", FACE="#0C1013", FACE_TOP="#2C363C",
                INSET="#07090B", INSET_TOP="#161B1F", SOCKET="#060708", WELL="#030405", WELL_TOP="#07090B",
                BODY="#1A2025", BODY_TOP="#3A464D", DIS_BODY="#0E1114",
                # the tube is blown out: white core, a breath of cyan and pink at the ends
                TUBE=("#E9FCFF", "#FFFFFF", "#FFFFFF", "#FFEAF8"), TUBE_REST=("#CDEFF7", "#E6F4F8", "#E9E8F4", "#F1D9E9"),
                TUBE_DIS=("#2B3439",) * 4, STRUCT="#3B4A52", STRUCT_HI="#7F9AA6",
                HALO=("#7FE6FF", "#A6EEFF", "#B9C8FF", "#FFB3E4"), HALO_REST=0.8, HALO_HOVER=1.1, HALO_ON=1.5,
                SHEEN="#56666E", SHEEN_ON="#FFFFFF", ARC_EMIT=0.8, FACE_LINE_PX=2.5, FACE_HALO_PX=4.0,
                FACE_SHEEN=0.0, PLATE_SHEEN="#4A5A62", GRID=0.0, LINE=1.8, BLOOM=1.5,
                MARK="#FFFFFF", MARK_DIM="#A7BAC2", ON_MARK="#06080A", DIS_MARK="#48545A",
                ACCENT=("#4CC6E6", "#2285B3"), ACCENT_HI=("#72D8F2", "#3499C6"), ACCENT_DIS=("#20272B", "#20272B"),
                HOT=("#F062B8", "#B8378A"), SOLO=("#3CC8EC", "#1E8FC0"), LAMP=("#5ED8F2", "#239FCC"),
                PRESS=("#4CC6E6", "#2285B3"),
                ARC_OFF="#252D32", ARC_OFF_HI="#333D43", ARC=("#DDF8FF", "#FFFFFF", "#FFFFFF", "#FFE1F4"),
                ARC_GLOW="#8FE8FF", ARC_GLOW_I=1.1,
                CAP="#101418", CAP_TOP="#2E383E", CAP_RING="#D5F4FB", CAP_RING_HI="#FFFFFF", NEEDLE="#FFFFFF",
                TRACK="#2A3338", HANDLE="#FFFFFF", HANDLE_HI="#FFFFFF",
                PAD_BODY="#15191D", PAD_LINE="#FFFFFF", PAD_LINE_TINT=0.5, PAD_HALO_TINT=1.0, PAD_FACE_TINT=0.2,
                PAD_SHEEN_TINT=0.45, SCROLL="#3A464C", SCROLL_HI="#6B7E86"),
            app=dict(
                chrome=dict(headerBg="#07090B", headerBorder="#E6F4F8", tabFillBottom="#0A0C0F", tabFillTop="#0A0C0F",
                            tabFillActiveBottom="#161B1F", tabFillActiveTop="#232A30", iconActive="#FFFFFF",
                            meatballLit="#FFFFFF"),
                ui=dict(textFaint="#5B6A71", accent="#DDF7FF", warn="#FFE08A", danger="#FF9BC8", ok="#B8FFE0"),
                surface=dict(card="#0A0D10F5", cardEdge="#E6F4F8", divider="#1C2226", scrim="#000000C0"),
                display=dict(text="#F4FEFF", textDim="#7FA3AE", textAlt="#FFD6EE", warn="#FF9BC8"),
                key=dict(faceOff="#0C0F12", edgeOff="#CDEFF7", bankFaceOff="#0C0F12", bankEdgeOff="#3B4A52",
                         velOn="#FFFFFF"),
                pad=dict(empty="#0A0C0F80", ringWhite="#FFFFFF4D", ringBack="#02060CE0"),
                review=dict(bar="#07090BF0", barRule="#FFFFFF22"),
                tracks=dict(backdrop="#050607", strip="#0A0C0F", rowWithSample="#161B1F", rowEmpty="#0E1114",
                            rowNotesNoSample="#2A1A24", text="#E6F4F8", ruler="#FFFFFFB0", recMarker="#FF9BC8DC",
                            scrollbar="#FFFFFF26")),
        ),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
