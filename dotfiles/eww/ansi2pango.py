#!/usr/bin/env python3
# Convert the small subset of ANSI SGR codes fastfetch emits (reset, bold,
# the eight base foreground colors, default-fg) into Pango markup so an
# eww label with :markup true can render fastfetch's colored logo/keys.
import re
import sys

ANSI_RE = re.compile(r"\x1b\[([0-9;]*)m")

COLORS = {
    30: "#2e3436", 31: "#e01b24", 32: "#33d17a", 33: "#f5c211",
    34: "#3584e4", 35: "#9141ac", 36: "#00b3cc", 37: "#d3d7cf",
    90: "#555753", 91: "#ff6b6b", 92: "#8ff0a4", 93: "#ffd85a",
    94: "#62a0ea", 95: "#dc8add", 96: "#4fd2e8", 97: "#eeeeec",
}


def escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def convert(raw):
    # Span boundaries are only emitted right before a real chunk of text, not
    # after every SGR code -- fastfetch emits several codes back-to-back
    # (reset, bold, color) with nothing between them, and closing/reopening
    # a span at each one produces empty <span></span> noise.
    out = []
    bold, fg = False, None
    open_bold, open_fg = False, None
    span_open = False

    def ensure_span():
        nonlocal span_open, open_bold, open_fg
        if span_open and (open_bold, open_fg) == (bold, fg):
            return
        if span_open:
            out.append("</span>")
            span_open = False
        attrs = []
        if bold:
            attrs.append('weight="bold"')
        if fg:
            attrs.append(f'foreground="{fg}"')
        if attrs:
            out.append(f"<span {' '.join(attrs)}>")
            span_open = True
            open_bold, open_fg = bold, fg

    pos = 0
    for m in ANSI_RE.finditer(raw):
        text = raw[pos : m.start()]
        if text:
            ensure_span()
            out.append(escape(text))
        pos = m.end()

        codes = [int(c) for c in m.group(1).split(";") if c != ""] or [0]
        for code in codes:
            if code == 0:
                bold, fg = False, None
            elif code == 1:
                bold = True
            elif code == 39:
                fg = None
            elif code in COLORS:
                fg = COLORS[code]

    tail = raw[pos:]
    if tail:
        ensure_span()
        out.append(escape(tail))
    if span_open:
        out.append("</span>")
    return "".join(out)


sys.stdout.write(convert(sys.stdin.read()))
