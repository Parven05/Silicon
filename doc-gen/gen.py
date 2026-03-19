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
# Matches @(anything) or @word — used with .match() not .fullmatch()
# so it correctly handles attributes even when stripped line has trailing content.
_ATTR_RE = re.compile(r"@(?:\([^)]*\)|\w+)\s*$")
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


def _extract_proc_params(decl_line: str) -> str:
    """
    Extract the parameter list from a proc declaration line, handling nested
    parentheses correctly (e.g. `foo :: proc(cb: proc() -> b, x: int)`).
    Searches for `:: proc` then reads the balanced parens after it.
    Returns the inner content, or "" if not found.
    """
    # Find the start of the parameter list — the '(' that follows ':: proc'
    proc_idx = decl_line.find(":: proc")
    if proc_idx == -1:
        return ""
    search_from = proc_idx + len(":: proc")

    paren_start = decl_line.find("(", search_from)
    if paren_start == -1:
        return ""

    depth = 0
    for i in range(paren_start, len(decl_line)):
        ch = decl_line[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                inner = decl_line[paren_start + 1 : i]
                return _WS_RE.sub(" ", inner.strip())

    return ""  # unbalanced — skip


def extract_signature(block: str, cat: str) -> dict[str, str]:
    """
    For PROC blocks extract params (depth-aware) and return type.
    Returns {"params": str, "returns": str} — both may be empty.
    """
    if cat != "PROC":
        return {"params": "", "returns": ""}

    first_line = block.split("\n")[0]
    params = _extract_proc_params(first_line)

    returns = ""
    rm = _RET_RE.search(first_line)
    if rm:
        returns = _WS_RE.sub(" ", rm.group(1).strip().rstrip("{").strip())

    return {"params": params, "returns": returns}


def preceding_metadata(text: str, match_start: int) -> tuple[list[str], list[str]]:
    """
    Walk backwards from `match_start` and collect, in source order:
      - @attribute lines  (sit directly above the declaration)
      - comment lines     (sit above the attributes)
    A blank line stops collection once any content has been seen.

    Return order: (comments, attrs) — comments first so format_snippet
    can emit them in the correct source order: comments -> attrs -> decl.
    """
    lines = text[:match_start].splitlines()
    comments: list[str] = []
    attrs: list[str] = []
    seen_any = False

    for line in reversed(lines):
        stripped = line.strip()
        if _ATTR_RE.search(stripped):
            # Only treat as attribute if the line IS an attribute (not code
            # that happens to contain @something in the middle).
            attrs.insert(0, stripped)
            seen_any = True
        elif stripped.startswith(("//", "/*")) or stripped.endswith("*/"):
            comments.insert(0, stripped)
            seen_any = True
        elif stripped == "" and not seen_any:
            # Blank line before we have seen anything — keep scanning
            continue
        else:
            # Non-empty, non-comment, non-attribute line — stop
            break

    return comments, attrs


def format_snippet(comments: list[str], attrs: list[str], block: str) -> str:
    """
    Dedent the code block, then prepend in correct source order:
    comments -> attributes -> declaration block.
    """
    dedented = textwrap.dedent(block).rstrip()
    # Correct order: comments first, then attributes, then the block
    prefix = comments + attrs
    return "\n".join(prefix + [dedented]).strip()


def package_path(file_path: Path, source_dir: Path) -> str:
    """Return relative path from src root, e.g. 'renderer/mesh.odin'."""
    try:
        return str(file_path.relative_to(source_dir))
    except ValueError:
        return file_path.name


def make_item_id(pkg: str, name: str) -> str:
    """
    Build a collision-free HTML id from package path + symbol name.
    e.g. 'renderer/mesh.odin' + 'Mesh' -> 'renderer-mesh-odin--Mesh'
    """
    safe_pkg = re.sub(r"[^A-Za-z0-9]", "-", pkg)
    return f"{safe_pkg}--{name}"


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
    item_id = escape(item["id"])
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
        f"\n        <details id='{item_id}'>",
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
            item_id = make_item_id(pkg, name)

            items.append({
                "id": item_id,
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
            "id": item["id"],
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
