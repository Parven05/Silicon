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
# Compiled patterns (all at module level — compiled once)
# ---------------------------------------------------------------------------
_DECL_RE = re.compile(r"(\w+)\s*::\s*(struct|proc|enum|union)")
_RET_RE  = re.compile(r"->\s*([^{]+)")
# Anchored to end-of-line so only genuine attribute lines match,
# not code that happens to contain @ in the middle.
_ATTR_RE = re.compile(r"@(?:\([^)]*\)|\w+)\s*$")
_WS_RE   = re.compile(r"\s+")
# Used in make_item_id — compiled once here instead of inside the function
_ID_UNSAFE_RE = re.compile(r"[^A-Za-z0-9]")
# Template placeholder substitution — one regex pass instead of three .replace()
_TMPL_RE = re.compile(r"\{\{(content|toc_json|item_count)\}\}")


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
def get_block(text: str, start: int) -> str | None:
    """
    Return the balanced-brace block starting at `start`.
    Uses a while loop (no range object allocation) scanning only as far
    as needed. Returns the declaration line for brace-free procs, or
    None on unclosed braces (malformed source — skip the symbol).
    """
    n = len(text)
    # Pre-compute line end for the no-brace case
    line_end = text.find("\n", start)
    if line_end == -1:
        line_end = n

    depth = 0
    found = False
    i = start
    while i < n:
        ch = text[i]
        if ch == "{":
            depth += 1
            found = True
        elif ch == "}" and found:
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
        i += 1

    # Never found an opening brace → single-line declaration
    if not found:
        return text[start:line_end]

    return None  # opened but never closed — malformed


def _extract_proc_params(decl_line: str) -> str:
    """
    Depth-aware parameter extraction for proc declarations.
    Finds `:: proc` first then reads balanced parens from that position,
    so nested proc-type params like `cb: proc() -> bool` are handled correctly.
    """
    proc_idx = decl_line.find(":: proc")
    if proc_idx == -1:
        return ""
    paren_start = decl_line.find("(", proc_idx + 7)  # 7 = len(":: proc")
    if paren_start == -1:
        return ""

    depth = 0
    i = paren_start
    n = len(decl_line)
    while i < n:
        ch = decl_line[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                inner = decl_line[paren_start + 1 : i]
                return _WS_RE.sub(" ", inner.strip())
        i += 1
    return ""  # unbalanced parens


def extract_signature(block: str, cat: str) -> dict[str, str]:
    """
    Extract params and return type from the first line of a PROC block.
    Returns {"params": str, "returns": str} — both may be empty.
    Non-PROC symbols return empty dicts immediately.
    """
    if cat != "PROC":
        return {"params": "", "returns": ""}

    first_line = block.split("\n", 1)[0]  # maxsplit=1, no full split needed
    params = _extract_proc_params(first_line)

    returns = ""
    rm = _RET_RE.search(first_line)
    if rm:
        returns = _WS_RE.sub(" ", rm.group(1).strip().rstrip("{").strip())

    return {"params": params, "returns": returns}


def preceding_metadata(text: str, match_start: int) -> tuple[list[str], list[str]]:
    """
    Walk backwards from `match_start` collecting comments and @attributes.
    Only scans the last ~60 lines before the match to avoid copying the
    entire file for each symbol.

    Returns (comments, attrs) in source order — comments first, then attrs —
    so format_snippet can emit: comments -> attrs -> declaration.

    A blank line stops collection once any content has been seen.
    """
    # Slice only the region we actually need (last 60 lines max)
    region_start = text.rfind("\n", 0, match_start)
    for _ in range(59):  # walk back up to 60 lines total
        pos = text.rfind("\n", 0, region_start)
        if pos == -1:
            region_start = 0
            break
        region_start = pos

    lines = text[region_start:match_start].splitlines()
    comments: list[str] = []
    attrs: list[str] = []
    seen_any = False

    for line in reversed(lines):
        stripped = line.strip()
        if _ATTR_RE.search(stripped):
            attrs.insert(0, stripped)
            seen_any = True
        elif stripped.startswith(("//", "/*")) or stripped.endswith("*/"):
            comments.insert(0, stripped)
            seen_any = True
        elif not stripped and not seen_any:
            continue  # leading blank before any content — keep scanning
        else:
            break  # code line or blank after content — stop

    return comments, attrs


def format_snippet(comments: list[str], attrs: list[str], block: str) -> str:
    """
    Dedent the block, prepend in correct Odin source order:
    comments → attributes → declaration.
    """
    dedented = textwrap.dedent(block).rstrip()
    return "\n".join(comments + attrs + [dedented]).strip()


def package_path(file_path: Path, source_dir: Path) -> str:
    """Relative path from src root, e.g. 'renderer/mesh.odin'."""
    try:
        return str(file_path.relative_to(source_dir))
    except ValueError:
        return file_path.name


def make_item_id(pkg: str, name: str) -> str:
    """
    Collision-free HTML id: package path + symbol name.
    Uses module-level compiled pattern so re.sub isn't recompiled each call.
    e.g. 'renderer/mesh.odin' + 'Mesh' → 'renderer-mesh-odin--Mesh'
    """
    return _ID_UNSAFE_RE.sub("-", pkg) + "--" + name


# ---------------------------------------------------------------------------
# HTML builders
# ---------------------------------------------------------------------------
def _build_sig_html(item: dict) -> str:
    if item["cat"] != "PROC":
        return ""
    params  = item["sig"]["params"]
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
    return (
        "\n            <div class='sig-bar'>"
        + " &nbsp;&middot;&nbsp; ".join(parts)
        + "</div>"
    )


def build_item_html(item: dict) -> str:
    item_id   = escape(item["id"])
    name      = escape(item["name"])
    cat       = item["cat"]
    pkg       = escape(item["pkg"])
    code      = escape(item["code"])
    badge_cls = cat.lower()
    sig_html  = _build_sig_html(item)
    attrs_html = "".join(
        f"<span class='attr'>{escape(a)}</span>" for a in item["attrs"]
    )

    return (
        f"\n        <details id='{item_id}'>"
        f"\n            <summary>"
        f"<span class='item-name'>{name}</span>"
        f"{attrs_html}"
        f"<span class='badge badge-{badge_cls}'>{cat}</span>"
        f"</summary>"
        f"{sig_html}"
        f"\n            <div class='content'>"
        f"<div class='code-header'>"
        f"<span class='code-file'>{pkg}</span>"
        f"<button class='copy-btn' onclick='copyCode(this)' title='Copy'>&#x2398;</button>"
        f"</div>"
        f"<pre class='language-odin'><code class='language-odin'>{code}</code></pre>"
        f"</div>\n        </details>"
    )


def build_html(items: list[dict]) -> str:
    parts: list[str] = []
    last_pkg = None

    for item in items:
        pkg = item["pkg"]
        if pkg != last_pkg:
            if last_pkg:
                parts.append("</div>")
            safe_id   = escape(_ID_UNSAFE_RE.sub("-", pkg))
            pkg_label = escape(pkg)
            parts.append(
                f"<div class='file-section' id='sec-{safe_id}'>"
                f"<div class='file-header' data-pkg='{pkg_label}'>{pkg_label}</div>"
            )
            last_pkg = pkg
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
        pkg     = package_path(path, source_dir)

        for m in _DECL_RE.finditer(content):
            name  = m.group(1)
            cat   = m.group(2).upper()
            block = get_block(content, m.start())
            if not block:
                continue

            comments, attrs = preceding_metadata(content, m.start())
            items.append({
                "id":       make_item_id(pkg, name),
                "name":     name,
                "cat":      cat,
                "file":     path.name,
                "pkg":      pkg,
                "attrs":    attrs,
                "comments": comments,
                "sig":      extract_signature(block, cat),
                "code":     format_snippet(comments, attrs, block),
            })

    items.sort(key=lambda x: (x["pkg"], SORT_ORDER.get(x["cat"], 4), x["name"]))
    return items


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main() -> None:
    if not SOURCE_DIR.exists():
        raise SystemExit(f"Error: source directory not found -> {SOURCE_DIR}")

    items        = parse_source(SOURCE_DIR)
    html_content = build_html(items)

    toc_data: dict[str, list[dict]] = {}
    for item in items:
        toc_data.setdefault(item["pkg"], []).append({
            "id":   item["id"],
            "name": item["name"],
            "cat":  item["cat"],
        })

    # Build substitution map for one-pass template replacement
    replacements = {
        "content":    html_content,
        "toc_json":   json.dumps(toc_data, ensure_ascii=False),
        "item_count": str(len(items)),
    }

    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    output   = _TMPL_RE.sub(lambda m: replacements[m.group(1)], template)

    OUTPUT_HTML.write_text(output, encoding="utf-8")
    print(f"Done: {len(items)} items -> {OUTPUT_HTML}")


if __name__ == "__main__":
    main()
