"""
gen.py — Silicon doc generator
Parses Odin source files and emits a single-file HTML reference doc.
"""

import json
import re
import textwrap
from html import escape
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = BASE_DIR.parent
SOURCE_DIR = PROJECT_ROOT / "src"
OUTPUT_HTML = BASE_DIR / "index.html"
TEMPLATE_PATH = BASE_DIR / "template.html"

SORT_ORDER = {"STRUCT": 1, "ENUM": 2, "PROC": 3}

# ---------------------------------------------------------------------------
# Compiled patterns
# ---------------------------------------------------------------------------
_DECL_RE = re.compile(r"(\w+)\s*::\s*(struct|proc|enum|union)")
_RET_RE = re.compile(r"->\s*([^{]+)")
_PARAM_RE = re.compile(r"\(([^)]*)\)")
_ATTR_RE = re.compile(r"@\s*\([^)]*\)|@\w+")
_WS_RE = re.compile(r"\s+")


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
def get_block(text: str, start: int) -> str | None:
    """
    Return the balanced-brace block starting at `start`.
    If no opening brace is found, returns only the declaration line
    (handles single-line procs like `foo :: proc() -> bool`).
    Returns None on unclosed braces (malformed source).
    """
    depth = 0
    found = False
    line_end = text.find("\n", start)
    if line_end == -1:
        line_end = len(text)

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
        return text[start:line_end]

    return None  # unclosed brace; skip


def preceding_metadata(text: str, match_start: int) -> tuple[list[str], list[str]]:
    """
    Walk backwards from `match_start` and collect:
      - contiguous comment lines  (returned as plain strings, stripped)
      - @attribute lines          (returned as plain strings, stripped)
    A blank line stops collection once any content has been seen.
    """
    lines = text[:match_start].splitlines()
    comments: list[str] = []
    attrs: list[str] = []

    for line in reversed(lines):
        stripped = line.strip()
        if _ATTR_RE.fullmatch(stripped):
            attrs.insert(0, stripped)
        elif stripped.startswith(("//", "/*")) or stripped.endswith("*/"):
            comments.insert(0, stripped)
        elif stripped == "" and not comments and not attrs:
            continue
        else:
            break

    return comments, attrs


def extract_signature(block: str, cat: str) -> dict[str, str]:
    """
    For PROC blocks extract params and return type.
    Returns {"params": str, "returns": str} - both may be empty.
    """
    if cat != "PROC":
        return {"params": "", "returns": ""}

    first_line = block.split("\n")[0]
    params = ""
    returns = ""

    pm = _PARAM_RE.search(first_line)
    if pm:
        params = _WS_RE.sub(" ", pm.group(1).strip())

    rm = _RET_RE.search(first_line)
    if rm:
        returns = _WS_RE.sub(" ", rm.group(1).strip().rstrip("{").strip())

    return {"params": params, "returns": returns}


def format_snippet(comments: list[str], attrs: list[str], block: str) -> str:
    """Dedent code block, prepend attributes then comments."""
    dedented = textwrap.dedent(block).rstrip()
    prefix = attrs + comments
    return "\n".join(prefix + [dedented]).strip()


def package_path(file_path: Path, source_dir: Path) -> str:
    """Return relative path from src root, e.g. 'renderer/mesh.odin'."""
    try:
        return str(file_path.relative_to(source_dir))
    except ValueError:
        return file_path.name


# ---------------------------------------------------------------------------
# HTML builders
# ---------------------------------------------------------------------------
def _build_sig_html(item: dict) -> str:
    if item["cat"] != "PROC":
        return ""
    params = item["sig"]["params"]
    returns = item["sig"]["returns"]
    if not params and not returns:
        return ""
    parts = []
    if params:
        parts.append(
            "<span class='sig-label'>params</span> "
            f"<span class='sig-val'>{escape(params)}</span>"
        )
    if returns:
        parts.append(
            "<span class='sig-label'>returns</span> "
            f"<span class='sig-val sig-ret'>{escape(returns)}</span>"
        )
    inner = " &nbsp;&middot;&nbsp; ".join(parts)
    return f"\n            <div class='sig-bar'>{inner}</div>"


def build_item_html(item: dict) -> str:
    name = escape(item["name"])
    cat = item["cat"]
    pkg = escape(item["pkg"])
    code = escape(item["code"])
    badge_cls = cat.lower()
    sig_html = _build_sig_html(item)
    attrs_html = "".join(
        f"<span class='attr'>{escape(a)}</span>" for a in item["attrs"]
    )

    parts = [
        f"\n        <details id='item-{name}'>",
        "\n            <summary>",
        f"<span class='item-name'>{name}</span>",
        attrs_html,
        f"<span class='badge badge-{badge_cls}'>{cat}</span>",
        "</summary>",
        sig_html,
        "\n            <div class='content'>",
        "<div class='code-header'>",
        f"<span class='code-file'>{pkg}</span>",
        "<button class='copy-btn' onclick='copyCode(this)' title='Copy'>&#x2398;</button>",
        "</div>",
        f"<pre class='language-odin'><code class='language-odin'>{code}</code></pre>",
        "</div>\n        </details>",
    ]
    return "".join(parts)


def build_html(items: list[dict]) -> str:
    parts: list[str] = []
    last_pkg = None

    for item in items:
        if item["pkg"] != last_pkg:
            if last_pkg:
                parts.append("</div>")
            safe_id = escape(
                item["pkg"].replace("/", "-").replace("\\", "-").replace(".", "-")
            )
            pkg_label = escape(item["pkg"])
            parts.append(
                f"<div class='file-section' id='sec-{safe_id}'>"
                f"<div class='file-header' data-pkg='{pkg_label}'>{pkg_label}</div>"
            )
            last_pkg = item["pkg"]
        parts.append(build_item_html(item))

    if last_pkg:
        parts.append("</div>")

    return "".join(parts)


# ---------------------------------------------------------------------------
# Core parsing
# ---------------------------------------------------------------------------
def parse_source(source_dir: Path) -> list[dict]:
    items: list[dict] = []

    paths = sorted(
        source_dir.rglob("*.odin"),
        key=lambda p: p.relative_to(source_dir).parts,
    )

    for path in paths:
        content = path.read_text(encoding="utf-8")
        pkg = package_path(path, source_dir)

        for m in _DECL_RE.finditer(content):
            name = m.group(1)
            cat = m.group(2).upper()
            block = get_block(content, m.start())
            if not block:
                continue

            comments, attrs = preceding_metadata(content, m.start())
            sig = extract_signature(block, cat)

            items.append({
                "name": name,
                "cat": cat,
                "file": path.name,
                "pkg": pkg,
                "attrs": attrs,
                "comments": comments,
                "sig": sig,
                "code": format_snippet(comments, attrs, block),
            })

    items.sort(key=lambda x: (x["pkg"], SORT_ORDER.get(x["cat"], 4), x["name"]))
    return items


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main() -> None:
    if not SOURCE_DIR.exists():
        raise SystemExit(f"Error: source directory not found -> {SOURCE_DIR}")

    items = parse_source(SOURCE_DIR)
    html_content = build_html(items)

    toc_data: dict[str, list[dict]] = {}
    for item in items:
        toc_data.setdefault(item["pkg"], []).append({
            "name": item["name"],
            "cat": item["cat"],
        })
    toc_json = json.dumps(toc_data, ensure_ascii=False)

    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    output = (
        template
        .replace("{{content}}", html_content)
        .replace("{{toc_json}}", toc_json)
        .replace("{{item_count}}", str(len(items)))
    )
    OUTPUT_HTML.write_text(output, encoding="utf-8")
    print(f"Done: {len(items)} items -> {OUTPUT_HTML}")


if __name__ == "__main__":
    main()
