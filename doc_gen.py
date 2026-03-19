import os
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
    <title>Silicon API</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-monokai.min.css" rel="stylesheet" />
    <style>
        :root {{
            --bg: #121212; --card: #1a1a1a; --text: #dcdcdc; --border: #252525;
            --m-bg: #272822; --m-pink: #f92672; --m-blue: #66d9ef;
            --m-green: #a6e22e; --m-yellow: #e6db74; --m-gray: #75715e;
        }}
        body {{ background: var(--bg); color: var(--text); font-family: 'Inter', sans-serif; margin: 0; padding: 20px; display: flex; justify-content: center; }}
        .container {{ width: 100%; max-width: 950px; }}
        header {{ margin-bottom: 20px; border-left: 3px solid #333; padding-left: 15px; }}
        h1 {{ font-size: 1.4rem; margin: 0; color: #fff; }}
        .tagline {{ color: #666; font-size: 0.8rem; }}
        #search {{ width: 100%; background: #1e1e1e; border: 1px solid var(--border); padding: 10px 15px; color: #fff; border-radius: 4px; margin-bottom: 20px; outline: none; }}

        .file-section {{ margin-top: 30px; }}
        .file-header {{
            font-size: 0.7rem; font-weight: 800; color: #555; text-transform: uppercase;
            letter-spacing: 2px; margin-bottom: 10px; border-bottom: 1px solid var(--border); padding-bottom: 5px;
        }}

        details {{ border: 1px solid var(--border); border-radius: 4px; margin-bottom: 4px; background: var(--card); overflow: hidden; }}
        summary {{ padding: 10px 15px; cursor: pointer; display: flex; align-items: center; list-style: none; font-family: 'JetBrains Mono', monospace; font-size: 0.82rem; color: #aaa; }}
        summary:hover {{ background: #222; color: #fff; }}
        .badge {{ margin-left: auto; font-size: 0.55rem; padding: 2px 6px; border-radius: 2px; border: 1px solid #333; color: #666; font-weight: 700; }}

        .content {{ padding: 0; border-top: 1px solid var(--border); }}
        pre[class*="language-"] {{ margin: 0 !important; padding: 15px !important; background: var(--m-bg) !important; border-radius: 0 !important; }}
        code[class*="language-"] {{ font-family: 'JetBrains Mono', monospace !important; font-size: 0.85rem !important; text-shadow: none !important; color: #f8f8f2 !important; }}

        .token.comment {{ color: var(--m-gray) !important; }}
        .token.keyword, .token.operator {{ color: var(--m-pink) !important; }}
        .token.function {{ color: var(--m-green) !important; }}
        .token.string {{ color: var(--m-yellow) !important; }}
        .token.builtin, .token.attr-name {{ color: var(--m-blue) !important; }}
    </style>
</head>
<body>
    <div class="container">
        <header><h1>{p_title}</h1><div class="tagline">{p_tagline}</div></header>
        <input type="text" id="search" placeholder="Search API...">
        <div id="api-root">{content}</div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script>
        Prism.languages.odin = Prism.languages.extend('clike', {{
            'keyword': /\\b(?:package|import|proc|struct|enum|union|return|defer|if|else|for|switch|case|dynamic|map|bit_set)\\b/,
            'operator': /->|::|:=|\\.\\.|[\\+\\-\\*\\/%=<>!&|\\^~]+/,
            'attr-name': /@\\w+/,
            'builtin': /\\b(?:[uif]\\d+|bool|string|rawptr|any|int|uint)\\b/
        }});
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
    count = 0
    for i in range(start_index, len(text)):
        if text[i] == '{': count += 1
        elif text[i] == '}':
            count -= 1
            if count == 0: return text[start_index:i+1]
    return None

def extract_items(content, filename):
    results = []
    lines = content.splitlines()
    pattern = re.compile(r"^(?P<name>\w+)\s*::\s*")

    for i, line in enumerate(lines):
        match = pattern.match(line)
        if match:
            name = match.group("name")
            if name in ["import", "package"]: continue

            body_lines = []
            for k in range(i, len(lines)):
                body_lines.append(lines[k])
                if "{" in lines[k]:
                    block = get_balanced_block("\n".join(lines[k:]), 0)
                    if block:
                        body_lines[-1] = block
                        break
                elif ";" in lines[k] or (k > i and lines[k].strip() == ""): break

            rem = " ".join(body_lines)
            cat = None
            if "proc" in rem: cat = "PROC"
            elif "struct" in rem: cat = "STRUCT"
            elif "enum" in rem: cat = "ENUM"

            # Only proceed if it is a Proc, Struct, or Enum
            if cat:
                comment_lines = []
                for j in range(i-1, -1, -1):
                    prev = lines[j].strip()
                    if prev.startswith("//") or prev.endswith("*/"): comment_lines.insert(0, lines[j])
                    elif prev == "": continue
                    else: break

                full_code = "\n".join(comment_lines + body_lines).strip()
                results.append({"name": name, "category": cat, "code": full_code, "file": filename})
    return results

def parse():
    all_items = []
    if not os.path.exists(SOURCE_DIR): return
    for root, _, files in os.walk(SOURCE_DIR):
        for file in sorted(files):
            if not file.endswith(".odin"): continue
            with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                all_items.extend(extract_items(f.read(), file))

    # Organized Order: File -> Category (Struct -> Enum -> Proc)
    cat_order = {"STRUCT": 1, "ENUM": 2, "PROC": 3}
    all_items.sort(key=lambda x: (x['file'], cat_order.get(x['category'], 4), x['name']))

    html_output, current_file = "", None
    for item in all_items:
        if item['file'] != current_file:
            current_file = item['file']
            html_output += f"<div class='file-section'><div class='file-header'>{current_file}</div>"

        safe_code = item['code'].replace("<", "&lt;").replace(">", "&gt;")
        html_output += f"""
        <details>
            <summary>{item['name']}<div class="badge">{item['category']}</div></summary>
            <div class="content"><pre class="language-odin"><code class="language-odin">{safe_code}</code></pre></div>
        </details>"""

        # Close file-section div if next item is a new file or last item
        idx = all_items.index(item)
        if idx == len(all_items) - 1 or all_items[idx + 1]['file'] != current_file:
            html_output += "</div>"

    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        f.write(HTML_TEMPLATE.format(content=html_output, p_title=PROJECT_TITLE, p_tagline=PROJECT_TAGLINE))

if __name__ == "__main__":
    parse()
