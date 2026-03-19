import os
import datetime
import re

SOURCE_DIR = "src"
OUTPUT_DIR = "doc"
INDEX_FILE = os.path.join(OUTPUT_DIR, "index.html")

PROJECT_TITLE = "Silicon Master API"
PROJECT_TAGLINE = "High-performance renderer technical reference."

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Silicon API</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
    <style>
        :root {{
            --bg: #0d0e11; --card: #15171c; --text: #949eb1; --dim: #4d5566;
            --border: #1f2229; --accent: #61afef; --code-bg: #1a1d23;
        }}
        body {{ background: var(--bg); color: var(--text); font-family: 'Inter', sans-serif; margin: 0; display: flex; justify-content: center; padding: 40px 20px; }}
        .container {{ width: 100%; max-width: 960px; }}
        header {{ margin-bottom: 40px; border-left: 3px solid var(--accent); padding-left: 20px; }}
        h1 {{ color: #fff; font-size: 1.8rem; margin: 0; }}
        .tagline {{ color: var(--dim); font-size: 0.85rem; margin-top: 5px; }}
        #search {{ width: 100%; background: var(--card); border: 1px solid var(--border); padding: 14px 20px; color: #fff; border-radius: 6px; margin-bottom: 30px; outline: none; }}
        .section-label {{ font-size: 0.65rem; font-weight: 800; color: var(--dim); text-transform: uppercase; letter-spacing: 2px; margin: 40px 0 15px 0; display: flex; align-items: center; }}
        .section-label::after {{ content: ""; height: 1px; background: var(--border); flex-grow: 1; margin-left: 15px; }}
        details {{ background: var(--card); border: 1px solid var(--border); border-radius: 6px; margin-bottom: 8px; }}
        summary {{ padding: 14px 18px; cursor: pointer; display: flex; align-items: center; list-style: none; font-family: 'JetBrains Mono', monospace; font-size: 0.8rem; font-weight: 600; color: #e5e9f0; }}
        summary::-webkit-details-marker {{ display: none; }}
        summary:hover {{ background: #1c1f26; }}
        .badges {{ display: flex; gap: 6px; margin-left: auto; }}
        .badge {{ font-size: 0.55rem; padding: 2px 8px; border-radius: 3px; font-weight: 700; text-transform: uppercase; border: 1px solid transparent; }}
        .type-badge {{ background: rgba(97, 175, 239, 0.1); color: var(--accent); border-color: rgba(97, 175, 239, 0.2); }}
        .file-badge {{ color: var(--dim); border-color: var(--border); }}
        .content {{ padding: 0 18px 18px 18px; border-top: 1px solid var(--border); background: var(--code-bg); }}
        pre {{ margin: 0 !important; padding: 15px 0 !important; background: transparent !important; }}
        code {{ font-family: 'JetBrains Mono', monospace !important; font-size: 0.78rem !important; line-height: 1.5 !important; }}
    </style>
</head>
<body>
    <div class="container">
        <header><h1>{p_title}</h1><div class="tagline">{p_tagline}</div></header>
        <input type="text" id="search" placeholder="Filter API items...">
        <div id="api-root">{content}</div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script>
        document.getElementById('search').addEventListener('input', (e) => {{
            const term = e.target.value.toLowerCase();
            document.querySelectorAll('details').forEach(el => {{
                const name = el.querySelector('summary').innerText.toLowerCase();
                el.style.display = name.includes(term) ? 'block' : 'none';
            }});
        }});
    </script>
</body>
</html>
"""

def get_balanced_block(text, start_index):
    """Finds the matching closing brace for an opening one."""
    count = 0
    for i in range(start_index, len(text)):
        if text[i] == '{': count += 1
        elif text[i] == '}':
            count -= 1
            if count == 0: return text[start_index:i+1]
    return None

def extract_items(content, filename):
    results = []
    seen_names = set()
    # Find all global-level names: name :: or name :
    lines = content.splitlines()

    # Identify starts of global declarations
    pattern = re.compile(r"^(?P<name>\w+)\s*:\s*(?P<is_const>:)?")

    for i, line in enumerate(lines):
        match = pattern.match(line)
        if match:
            name = match.group("name")
            if name in seen_names or name == "import" or name == "package": continue

            # Look back for comments
            comment_lines = []
            for j in range(i-1, -1, -1):
                prev = lines[j].strip()
                if prev.startswith("//") or prev.endswith("*/"): comment_lines.insert(0, lines[j])
                elif prev == "" or prev.startswith("/*"): continue
                else: break

            # Capture the body
            body_lines = []
            found_block = False
            for k in range(i, len(lines)):
                body_lines.append(lines[k])
                if "{" in lines[k]:
                    found_block = True
                    # Reconstruct text from this point to find balanced braces
                    full_text_from_here = "\n".join(lines[k:])
                    block = get_balanced_block(full_text_from_here, 0)
                    if block:
                        # Replace the single line that had '{' with the full balanced block
                        body_lines[-1] = block
                        break
                elif ";" in lines[k] or (k > i and lines[k].strip() == ""):
                    break

            full_code = "\n".join(comment_lines + body_lines).strip()

            # Determine Category
            rem = " ".join(body_lines)
            if "proc" in rem: cat = "PROC"
            elif "struct" in rem: cat = "STRUCT"
            elif "enum" in rem: cat = "ENUM"
            elif match.group("is_const"): cat = "CONSTANT"
            else: cat = "VARIABLE"

            results.append({"name": name, "category": cat, "code": full_code, "file": filename})
            seen_names.add(name)

    return results

def parse():
    all_items = []
    if not os.path.exists(SOURCE_DIR): return

    for root, _, files in os.walk(SOURCE_DIR):
        for file in sorted(files):
            if not file.endswith(".odin"): continue
            with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                all_items.extend(extract_items(f.read(), file))

    order = {"CONSTANT": 1, "VARIABLE": 2, "STRUCT": 3, "ENUM": 4, "PROC": 5}
    all_items.sort(key=lambda x: (order.get(x['category'], 6), x['name']))

    html_output, current_cat = "", None
    for item in all_items:
        if item['category'] != current_cat:
            current_cat = item['category']
            html_output += f"<div class='section-label'>{current_cat}S</div>"

        safe_code = item['code'].replace("<", "&lt;").replace(">", "&gt;")
        html_output += f"""
        <details>
            <summary>{item['name']}<div class="badges">
            <span class="badge file-badge">{item['file']}</span>
            <span class="badge type-badge">{item['category']}</span></div></summary>
            <div class="content"><pre><code class="language-clike">{safe_code}</code></pre></div>
        </details>"""

    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        f.write(HTML_TEMPLATE.format(content=html_output, p_title=PROJECT_TITLE, p_tagline=PROJECT_TAGLINE))

if __name__ == "__main__":
    parse()
