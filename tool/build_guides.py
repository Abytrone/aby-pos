"""Builds USER_GUIDE.pdf and DEVELOPER_GUIDE.pdf from the Markdown files.

    pip install markdown
    python tool/build_guides.py            # both guides
    python tool/build_guides.py user       # one of them: user | developer

Needs Google Chrome or Microsoft Edge (it prints the PDF with the browser, so
the brand fonts in fonts/ and the logos in aby-brand-kit/ are used as they
are). Headings keep GitHub-style ids, so the guides' own contents links work.
"""

import html
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent

GUIDES = {
    "user": ("USER_GUIDE.md", "USER_GUIDE.pdf", "The Aby user guide"),
    "developer": ("DEVELOPER_GUIDE.md", "DEVELOPER_GUIDE.pdf", "Aby POS: Developer Guide"),
}

BROWSERS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]


def find_browser() -> str:
    for name in ("chrome", "google-chrome", "chromium", "msedge"):
        found = shutil.which(name)
        if found:
            return found
    for path in BROWSERS:
        if os.path.exists(path):
            return path
    sys.exit("Chrome or Edge was not found. Install one, or edit BROWSERS in tool/build_guides.py.")


def github_slug(value: str, separator: str = "-") -> str:
    """The id GitHub gives a heading, so [text](#1-getting-started) links work."""
    text = re.sub(r"<[^>]+>", "", html.unescape(value)).strip().lower()
    text = "".join(ch for ch in text if ch.isalnum() or ch in " -_" or unicodedata.category(ch).startswith("L"))
    return text.replace(" ", separator)


def font_face(family: str, file: str, weight: int) -> str:
    uri = (ROOT / "fonts" / file).as_uri()
    return f"@font-face {{ font-family: '{family}'; src: url('{uri}'); font-weight: {weight}; }}"


CSS = (
    "\n".join(
        [
            font_face("Figtree", "Figtree-Regular.ttf", 400),
            font_face("Figtree", "Figtree-Medium.ttf", 500),
            font_face("Figtree", "Figtree-SemiBold.ttf", 600),
            font_face("Figtree", "Figtree-Bold.ttf", 700),
            font_face("Figtree", "Figtree-ExtraBold.ttf", 800),
            font_face("Figtree", "Figtree-Black.ttf", 900),
            font_face("JetBrains Mono", "JetBrainsMono-Regular.ttf", 400),
            font_face("JetBrains Mono", "JetBrainsMono-Bold.ttf", 700),
        ]
    )
    + """
:root {
  --midnight: #101322; --ink: #101322; --muted: #5a5e6b; --line: #dfe1d8;
  --sunken: #ecede6; --lime: #c8f560; --blue: #3446e0; --blue-soft: #e6e9ff;
  --warning-soft: #fdf0d7;
}
@page {
  size: A4;
  margin: 18mm 16mm 20mm 16mm;
  @bottom-left { content: string(doctitle); font: 500 8pt 'Figtree', sans-serif; color: #5a5e6b; }
  @bottom-right { content: counter(page) ' / ' counter(pages); font: 600 8pt 'Figtree', sans-serif; color: #5a5e6b; }
}
@page :first { @bottom-left { content: none; } @bottom-right { content: none; } }
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body {
  font: 400 9.6pt/1.5 'Figtree', 'Segoe UI', sans-serif; color: var(--ink);
  margin: 0; hyphens: manual; overflow-wrap: break-word;
}
h1 { string-set: doctitle content(); }
h1, h2, h3, h4 { font-family: 'Figtree', sans-serif; color: var(--midnight); line-height: 1.2; break-after: avoid; }
h1 { font-weight: 900; font-size: 30pt; margin: 0 0 5mm; letter-spacing: -0.02em; }
h2 { font-weight: 800; font-size: 17pt; margin: 9mm 0 3mm; padding-bottom: 2mm; border-bottom: 3px solid var(--lime); break-before: page; }
h2:first-of-type { break-before: auto; }
h3 { font-weight: 800; font-size: 12.5pt; margin: 6mm 0 2mm; }
h4 { font-weight: 700; font-size: 10.5pt; margin: 4mm 0 1.5mm; }
p { margin: 0 0 2.6mm; }
a { color: var(--blue); text-decoration: none; }
strong { font-weight: 700; }
ul, ol { margin: 0 0 3mm; padding-left: 6mm; }
li { margin: 0.8mm 0; }
hr { border: 0; border-top: 1px solid var(--line); margin: 6mm 0; }
blockquote { margin: 3mm 0; padding: 2.5mm 4mm; background: #ecfbc9; border-left: 3px solid var(--lime); border-radius: 0 3mm 3mm 0; break-inside: avoid; }
blockquote.first { background: var(--blue-soft); border-left-color: var(--blue); }
blockquote p:last-child { margin-bottom: 0; }
code { font: 400 8.3pt 'JetBrains Mono', Consolas, monospace; background: var(--sunken); padding: 0.3mm 1.2mm; border-radius: 1.2mm; }
pre { background: var(--midnight); color: #f6f7f2; padding: 3mm 4mm; border-radius: 3mm; overflow: hidden; white-space: pre-wrap; break-inside: avoid; }
pre code { background: none; color: inherit; padding: 0; font-size: 7.8pt; }
table { border-collapse: collapse; width: 100%; margin: 2mm 0 4mm; font-size: 8.8pt; }
thead { display: table-header-group; }
th { text-align: left; font-weight: 700; background: var(--midnight); color: #f6f7f2; padding: 1.6mm 2.4mm; }
td { padding: 1.5mm 2.4mm; border-bottom: 1px solid var(--line); vertical-align: top; }
tr { break-inside: avoid; }
li::marker { color: #9bc42d; }
img { max-width: 100%; }
p[align=center] { text-align: center; }
.cover { height: 259mm; display: flex; flex-direction: column; justify-content: center; break-after: page; }
.cover p[align=center] { text-align: left; margin: 0 0 8mm; }
.cover img { width: 150px; }
.cover h1 { font-size: 34pt; margin-bottom: 6mm; }
.cover p { margin: 0 0 3mm; color: var(--muted); font-size: 9pt; }
.cover p strong { display: inline-block; background: var(--lime); color: var(--midnight); font-size: 12pt; font-weight: 800; padding: 1.5mm 3.5mm; border-radius: 2.5mm; }
.cover em { font-style: normal; }
"""
)


def render(key: str, browser: str) -> None:
    source, target, title = GUIDES[key]
    text = (ROOT / source).read_text(encoding="utf-8")
    body = markdown.markdown(
        text,
        extensions=["tables", "fenced_code", "toc", "sane_lists", "attr_list", "md_in_html"],
        extension_configs={"toc": {"slugify": github_slug, "permalink": False}},
        output_format="html5",
    )
    # The opening logo, title, tagline and "for whom" lines become the cover.
    body = re.sub(
        r'^\s*((?:<p align="center">.*?</p>\s*)?<h1[^>]*>.*?</h1>\s*(?:<p><strong>.*?</strong></p>\s*)?<p><em>.*?</em></p>)',
        r'<section class="cover">\1</section>',
        body,
        count=1,
        flags=re.S,
    )
    # Images by absolute path (a <base> tag would turn "#part" links into file links).
    body = re.sub(r'src="(?![a-z]+:)([^"]+)"', lambda m: f'src="{(ROOT / m.group(1)).as_uri()}"', body)
    # The first call-out (how to read the steps) is blue, the rest lime.
    body = body.replace("<blockquote>", '<blockquote class="first">', 1)
    page = (
        "<!doctype html><html lang='en'><head><meta charset='utf-8'>"
        f"<title>{html.escape(title)}</title>"
        f"<style>{CSS}</style></head><body>{body}</body></html>"
    )
    with tempfile.TemporaryDirectory() as tmp:
        page_file = Path(tmp) / f"{key}.html"
        page_file.write_text(page, encoding="utf-8")
        out = ROOT / target
        subprocess.run(
            [
                browser,
                "--headless=new",
                "--disable-gpu",
                "--no-pdf-header-footer",
                "--allow-file-access-from-files",
                f"--user-data-dir={Path(tmp) / 'profile'}",
                f"--print-to-pdf={out}",
                page_file.as_uri(),
            ],
            check=True,
            capture_output=True,
            timeout=300,
        )
    print(f"{target}: {out.stat().st_size // 1024} KB")


def main() -> None:
    keys = sys.argv[1:] or list(GUIDES)
    for key in keys:
        if key not in GUIDES:
            sys.exit(f"Unknown guide '{key}'. Use: {', '.join(GUIDES)}")
    browser = find_browser()
    for key in keys:
        render(key, browser)


if __name__ == "__main__":
    main()
