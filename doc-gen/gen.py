"""
gen.py — Silicon doc generator
Parses Odin source files and emits a single-file HTML reference doc.

File ordering: place `// N` (e.g. `// 1`, `// 2`) as the very first line
of any .odin file to control the order it appears in the docs.
Files without an order number are sorted alphabetically after numbered files.
"""

import json
import re
import textwrap
from datetime import datetime, timezone
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
_DECL_RE      = re.compile(r"(\w+)\s*::\s*(struct|proc|enum|union)")
_RET_RE       = re.compile(r"->\s*([^{]+)")
_ATTR_RE      = re.compile(r"@(?:\([^)]*\)|\w+)\s*$")
_WS_RE        = re.compile(r"\s+")
_ID_UNSAFE_RE = re.compile(r"[^A-Za-z0-9]")
_TMPL_RE      = re.compile(r"\{\{(content|toc_json|item_count|generated_at)\}\}")
_ORDER_RE     = re.compile(r"^//\s*(\d+)\s*$")


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
def get_file_order(content: str) -> int:
    first_line = content.split("\n", 1)[0].strip()
    m = _ORDER_RE.match(first_line)
    return int(m.group(1)) if m else 999999


def get_block(text: str, start: int) -> str | None:
    n = len(text)
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

    if not found:
        return text[start:line_end]
    return None


def _extract_proc_params(decl_line: str) -> str:
    proc_idx = decl_line.find(":: proc")
    if proc_idx == -1:
        return ""
    paren_start = decl_line.find("(", proc_idx + 7)
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
    return ""


def extract_signature(block: str, cat: str) -> dict[str, str]:
    if cat != "PROC":
        return {"params": "", "returns": ""}
    first_line = block.split("\n", 1)[0]
    params = _extract_proc_params(first_line)
    returns = ""
    rm = _RET_RE.search(first_line)
    if rm:
        returns = _WS_RE.sub(" ", rm.group(1).strip().rstrip("{").strip())
    return {"params": params, "returns": returns}


def preceding_metadata(text: str, match_start: int) -> tuple[list[str], list[str]]:
    region_start = text.rfind("\n", 0, match_start)
    for _ in range(59):
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
            if _ORDER_RE.match(stripped):
                break
            comments.insert(0, stripped)
            seen_any = True
        elif not stripped and not seen_any:
            continue
        else:
            break

    return comments, attrs


def format_snippet(comments: list[str], attrs: list[str], block: str) -> str:
    dedented = textwrap.dedent(block).rstrip()
    return "\n".join(comments + attrs + [dedented]).strip()


def package_path(file_path: Path, source_dir: Path) -> str:
    try:
        return str(file_path.relative_to(source_dir))
    except ValueError:
        return file_path.name


def make_item_id(pkg: str, name: str) -> str:
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


def _build_refs_html(refs: list[str]) -> str:
    """Build the 'Used by' bar listing symbols that reference this one."""
    if not refs:
        return ""
    links = " ".join(
        f"<a class='ref-link' href='#{escape(r)}'>{escape(r.split('--')[-1])}</a>"
        for r in refs
    )
    return f"\n            <div class='refs-bar'><span class='refs-label'>used by</span> {links}</div>"


def build_item_html(item: dict) -> str:
    item_id    = escape(item["id"])
    name       = escape(item["name"])
    cat        = item["cat"]
    pkg        = escape(item["pkg"])
    code       = escape(item["code"])
    badge_cls  = cat.lower()
    sig_html   = _build_sig_html(item)
    refs_html  = _build_refs_html(item.get("used_by", []))
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
        f"{refs_html}"
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
            safe_id    = escape(_ID_UNSAFE_RE.sub("-", pkg))
            pkg_label  = escape(pkg)
            # Strip .odin for display — basename only, no extension
            pkg_display = escape(Path(pkg).stem)
            sym_count  = item["pkg_count"]
            parts.append(
                f"<div class='file-section' id='sec-{safe_id}'>"
                f"<div class='file-header' data-pkg='{pkg_label}'>"
                f"{pkg_display}"
                f"<span class='file-sym-count'>{sym_count}</span>"
                f"</div>"
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
    file_data: list[tuple[int, str, Path, str]] = []

    for path in source_dir.rglob("*.odin"):
        content = path.read_text(encoding="utf-8")
        pkg     = package_path(path, source_dir)
        order   = get_file_order(content)
        file_data.append((order, pkg, path, content))

    file_data.sort(key=lambda x: (x[0], x[1]))

    for order, pkg, path, content in file_data:
        for m in _DECL_RE.finditer(content):
            name  = m.group(1)
            cat   = m.group(2).upper()
            block = get_block(content, m.start())
            if not block:
                continue
            comments, attrs = preceding_metadata(content, m.start())
            items.append({
                "id":         make_item_id(pkg, name),
                "name":       name,
                "cat":        cat,
                "file":       path.name,
                "pkg":        pkg,
                "file_order": order,
                "attrs":      attrs,
                "comments":   comments,
                "sig":        extract_signature(block, cat),
                "code":       format_snippet(comments, attrs, block),
                "raw_code":   block,  # kept for reference analysis
                "used_by":    [],     # filled in below
            })

    items.sort(key=lambda x: (x["file_order"], x["pkg"], SORT_ORDER.get(x["cat"], 4), x["name"]))

    # --- "Used by" back-link analysis ---
    # Build name -> item_id map
    name_to_id: dict[str, str] = {}
    for item in items:
        if item["name"] not in name_to_id:
            name_to_id[item["name"]] = item["id"]

    # For each item, scan its raw code for references to other known symbols
    ident_re = re.compile(r"\b([A-Za-z_]\w*)\b")
    # Build reverse: target_id -> set of caller item_ids
    used_by: dict[str, set[str]] = {item["id"]: set() for item in items}

    for item in items:
        caller_id = item["id"]
        for m in ident_re.finditer(item["raw_code"]):
            word = m.group(1)
            if word == item["name"]:
                continue  # skip self
            if word in name_to_id:
                target_id = name_to_id[word]
                if target_id != caller_id:
                    used_by[target_id].add(caller_id)

    # Attach sorted used_by lists (sorted for stable output)
    for item in items:
        item["used_by"] = sorted(used_by.get(item["id"], set()))
        del item["raw_code"]  # no longer needed

    # Symbol count per file
    pkg_counts: dict[str, int] = {}
    for item in items:
        pkg_counts[item["pkg"]] = pkg_counts.get(item["pkg"], 0) + 1
    for item in items:
        item["pkg_count"] = pkg_counts[item["pkg"]]

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

    now = datetime.now(timezone.utc).strftime("%B %d, %Y at %H:%M UTC")

    replacements = {
        "content":      html_content,
        "toc_json":     json.dumps(toc_data, ensure_ascii=False),
        "item_count":   str(len(items)),
        "generated_at": now,
    }

    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    output   = _TMPL_RE.sub(lambda m: replacements[m.group(1)], template)

    OUTPUT_HTML.write_text(output, encoding="utf-8")
    print(f"Done: {len(items)} items -> {OUTPUT_HTML}")


if __name__ == "__main__":
    main()
