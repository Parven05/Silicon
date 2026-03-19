import os
import re
import textwrap
from pathlib import Path
from html import escape

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BASE_DIR      = Path(__file__).parent.resolve()
PROJECT_ROOT  = BASE_DIR.parent
SOURCE_DIR    = PROJECT_ROOT / "src"
OUTPUT_HTML   = BASE_DIR / "index.html"
TEMPLATE_PATH = BASE_DIR / "template.html"

SORT_ORDER = {"STRUCT": 1, "ENUM": 2, "PROC": 3}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def get_block(text: str, start: int) -> str | None:
    """Return the balanced-brace block starting at `start`, or rest of line."""
    depth, found = 0, False
    for i in range(start, len(text)):
        ch = text[i]
        if ch == "{":
            depth += 1
            found = True
        elif ch == "}" and found:
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
    if not found:
        end = text.find("\n", start)
        return text[start:end] if end != -1 else text[start:]
    return None


def preceding_comments(text: str, match_start: int) -> list[str]:
    """Collect contiguous comment lines immediately before `match_start`."""
    lines = text[:match_start].splitlines()
    comments: list[str] = []
    for line in reversed(lines):
        stripped = line.strip()
        if stripped.startswith(("//", "/*")) or stripped.endswith("*/"):
            comments.insert(0, stripped)
        elif stripped == "":
            continue
        else:
            break
    return comments


def format_snippet(comments: list[str], block: str) -> str:
    """Dedent the code block independently, then prepend stripped comments."""
    dedented = textwrap.dedent(block).rstrip()
    return "\n".join(comments + [dedented]).strip()


def build_item_html(item: dict) -> str:
    code = escape(item["code"])
    return (
        f"\n        <details>"
        f"\n            <summary>{item['name']}"
        f"<span class='badge'>{item['cat']}</span></summary>"
        f"\n            <div class='content'>"
        f"<pre class='language-odin'><code class='language-odin'>{code}</code></pre>"
        f"</div>\n        </details>"
    )

# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------
def parse_source(source_dir: Path) -> list[dict]:
    items: list[dict] = []
    pattern = re.compile(r"(\w+)\s*::\s*(struct|proc|enum)")

    for path in sorted(source_dir.rglob("*.odin")):
        content = path.read_text(encoding="utf-8")
        for m in pattern.finditer(content):
            name  = m.group(1)
            cat   = m.group(2).upper()
            block = get_block(content, m.start())
            if not block:
                continue
            comments = preceding_comments(content, m.start())
            items.append({
                "name": name,
                "cat":  cat,
                "file": path.name,
                "code": format_snippet(comments, block),
            })

    items.sort(key=lambda x: (x["file"], SORT_ORDER.get(x["cat"], 4), x["name"]))
    return items


def build_html(items: list[dict]) -> str:
    parts: list[str] = []
    last_file = None

    for item in items:
        if item["file"] != last_file:
            if last_file:
                parts.append("</div>")
            parts.append(
                f"<div class='file-section'>"
                f"<div class='file-header'>{item['file']}</div>"
            )
            last_file = item["file"]
        parts.append(build_item_html(item))

    if last_file:
        parts.append("</div>")

    return "".join(parts)


def main() -> None:
    if not SOURCE_DIR.exists():
        raise SystemExit(f"Error: source directory not found → {SOURCE_DIR}")

    items = parse_source(SOURCE_DIR)
    html_content = build_html(items)

    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    OUTPUT_HTML.write_text(
        template.replace("{{content}}", html_content),
        encoding="utf-8",
    )
    print(f"Done: {len(items)} items written to {OUTPUT_HTML}")


if __name__ == "__main__":
    main()
