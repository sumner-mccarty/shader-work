"""Flat Dark + Flat Light — the lookkit re-expression of Tools/design_flat.py (proof spec).

    python Tools/looks/flat.py check | write | sheet | diff [--root DIR]

Unlit, non-RM, the look a phone can afford: form from value steps between neutral greys, one warm
accent for ON, thin crisp strokes — capless dials (arc + needle), square keys with a small corner,
device panels as flat blocks separated by darker gaps. The whole part vocabulary is the kit's
`unlit` class, whose defaults ARE Flat's tuned shape language, so this spec is palettes + app print.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lookkit import Look, main  # noqa: E402

LOOK = Look(
    title="Flat", style="Flat", prefix="Flat", slug="flat", cls="unlit", order=4, status="shipped",
    brief="Tools/design_flat.py (shipped before the kit)",
    blurb="Unlit and sharp. Form from value steps and one warm accent - no bevel, no shadow, no glow.",
    tagline="unlit, non-raymarched, DAW-style. The look a phone can afford.",
    note="The rig (Themes/Flat.theme) has every lamp off, and with no shadow authored anywhere the UI\n"
         "shadow capture pass idles.",
    displays="flat",                       # every screen a plain well with a crisp curve
    shape={"dial": {"silhouette": "needle"}, "key": {"corner": 0.78}},    # = the class defaults, stated
    waive={"light-controls": "Flat Light is a value-inverted daylight UI: keys go pale and every mark "
                             "flips dark through the key.* palette (no literal light glyphs, no emissive)"},
    modes={
        "dark": dict(
            track="Nebula", blurb="Charcoal and one orange. Unlit, sharp and cheap to draw - the phone look.",
            palette=dict(
                # plates, darkest to lightest: the gaps between docked panels are the darkest thing on screen
                GAP="#141414", BACK="#1B1B1B", WELL="#171717", INSET="#222222", SOCKET="#202020", FACE="#2A2A2A",
                BODY="#3E3E3E", BODY_HI="#494949", PRESS="#2E2E2E", BORDER=None,
                MARK="#D6D6D6", MARK_DIM="#9A9A9A", DIS_BODY="#343434", DIS_MARK="#5A5A5A", PRINT_DIM="#8C8C8C",
                ACCENT="#FF9F1C", ACCENT_HI="#FFB24D", ACCENT_LO="#E88B0B", ACCENT_DIS="#5C4122", ON_MARK="#161616",
                SOLO="#45ADF5", LAMP="#F5C431", HOT="#FF5A48",
                # dials / faders: grey track, light value, light needle
                ARC_OFF="#4D4D4D", ARC_OFF_HI="#5C5C5C", VALUE="#D9D9D9", VALUE_HI="#FFFFFF", DIS_ARC="#383838",
                TRACK="#474747", HANDLE="#D9D9D9", HANDLE_HI="#FFFFFF",
                PAD_BODY="#3A3A3A", PAD_TINT=0.8, PAD_LATCH="#FFFFFF", SCROLL="#4A4A4A", SCROLL_HI="#5A5A5A"),
            # App print. Light ink for PLATES only — the cream/silver modules print dark silkscreen that
            # PrintInk flips on a dark plate. No ink.key: C# prints dark marks on orange accent keys.
            app=dict(
                chrome=dict(headerBg="#1F1F1F"),
                ui=dict(textFaint="#666666"),
                surface=dict(cardEdge="#3A3A3A", divider="#1F1F1F", scrim="#0A0A0AB8"),
                display=dict(text="#E6E6E6", textAlt="#E6E6E6"),   # every readout in one ink
                key=dict(bankFaceOff="#353535", bankEdgeOff="#2A2A2A", velOff="#8C8C8C"),
                pad=dict(empty="#262626FF", ring="#FFFFFFFF", ringBack="#000000B8"),
                review=dict(bar="#1E1E1EF0"),
                tracks=dict(rowWithSample="#2E2E2E", rowEmpty="#262626", rowNotesNoSample="#3A2B2B", text="#BDBDBD",
                            playhead="#E6E6E6E6", recMarker="#FF4A3DDC")),
        ),
        "light": dict(
            track="Rosewater", blurb="Studio grey in daylight. Unlit, sharp and cheap to draw.",
            palette=dict(
                GAP="#A8A8A8", BACK="#B9B9B9", WELL="#E9E9E9", INSET="#C4C4C4", SOCKET="#C8C8C8", FACE="#D0D0D0",
                # a pale key DARKENS under the pointer; disabled sinks toward the plate instead
                BODY="#BDBDBD", BODY_HI="#B2B2B2", PRESS="#A9A9A9", BORDER=None,
                MARK="#1C1C1C", MARK_DIM="#555555", DIS_BODY="#C9C9C9", DIS_MARK="#A5A5A5", PRINT_DIM="#5A5A5A",
                ACCENT="#F28C00", ACCENT_HI="#FF9E1F", ACCENT_LO="#D67B00", ACCENT_DIS="#E2C9A6", ON_MARK="#141414",
                SOLO="#2A93E6", LAMP="#F2B800", HOT="#D0382B",
                ARC_OFF="#A6A6A6", ARC_OFF_HI="#959595", VALUE="#262626", VALUE_HI="#000000", DIS_ARC="#BBBBBB",
                TRACK="#A6A6A6", HANDLE="#262626", HANDLE_HI="#000000",
                PAD_BODY="#C2C2C2", PAD_TINT=0.75, PAD_LATCH="#1C1C1C", SCROLL="#A0A0A0", SCROLL_HI="#8C8C8C"),
            app=dict(
                chrome=dict(headerBg="#C2C2C2"),
                ui=dict(textFaint="#8A8A8A", warn="#B07A00"),
                surface=dict(card="#D6D6D6FA", cardEdge="#B0B0B0", divider="#C2C2C2"),
                key=dict(bankFaceOff="#C4C4C4", bankEdgeOff="#A9A9A9", glyphOff="#3C3C3C", velOn="#D67B00"),
                pad=dict(empty="#C8C8C8FF", ring="#12161CFF", ringBack="#FFFFFFA8"),
                # challenge slots and note rings drawn for pale lanes (the defaults are dark-look greys)
                review=dict(bar="#C4C4C4F0", slot="#8C8C8C", slotFill="#DADADA"),
                tracks=dict(backdrop="#BEBEBE", strip="#C6C6C6", rowWithSample="#D8D8D8", rowEmpty="#CFCFCF",
                            rowNotesNoSample="#E0CDCD", text="#262626", ruler="#4A4A4AE6", noteSeparator="#F2F2F2")),
        ),
    },
)

if __name__ == "__main__":
    sys.exit(main(LOOK))
