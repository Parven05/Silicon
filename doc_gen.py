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
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-monokai.min.css" rel="stylesheet" />
    <style>
        :root {{
            --bg: #181818;
            --card: #222222;
            --text: #dcdcdc;
            --border: #2d2d2d;
            /* Authentic Monokai Palette */
            --m-bg: #272822; --m-pink: #f92672; --m-blue: #66d9ef;
            --m-green: #a6e22e; --m-orange: #fd971f; --m-yellow: #e6db74; --m-gray: #75715e;
        }}
        body {{ background: var(--bg); color: var(--text); font-family: 'Inter', sans-serif; margin: 0; padding: 20px; display: flex; justify-content: center; }}
        .container {{ width: 100%; max-width: 900px; }}

        header {{ margin-bottom: 20px; border-left: 3px solid #444; padding-left: 15px; }}
        h1 {{ font-size: 1.4rem; margin: 0; color: #fff; }}
        .tagline {{ color: #777; font-size: 0.8rem; }}

        #search {{
            width: 100%; background: #252525; border: 1px solid var(--border);
            padding: 10px 15px; color: #fff; border-radius: 4px; margin-bottom: 20px; outline: none;
        }}

        .section-label {{
            font-size: 0.65rem; font-weight: 800; color: #555; text-transform: uppercase;
            letter-spacing: 2px; margin: 30px 0 10px 0; display: flex; align-items: center;
        }}
        .section-label::after {{ content: ""; height: 1px; background: var(--border); flex-grow: 1; margin-left: 15px; }}

        details {{ border: 1px solid var(--border); border-radius: 4px; margin-bottom: 4px; background: var(--card); overflow: hidden; }}
        summary {{
            padding: 10px 15px; cursor: pointer; display: flex; align-items: center;
            list-style: none; font-family: 'JetBrains Mono', monospace; font-size: 0.82rem; color: #bbb;
        }}
        summary:hover {{ background: #2a2a2a; color: #fff; }}
        .badges {{ display: flex; gap: 6px; margin-left: auto; }}
        .badge {{ font-size: 0.55rem; padding: 2px 6px; border-radius: 2px; border: 1px solid #333; color: #666; font-weight: 700; }}

        /* FORCED MONOKAI CODE BLOCK */
        .content {{ padding: 0; border-top: 1px solid var(--border); }}
        pre[class*="language-"] {{
            margin: 0 !important; padding: 20px !important;
            background: var(--m-bg) !important; border-radius: 0 !important;
        }}
        code[class*="language-"] {{
            font-family: 'JetBrains Mono', monospace !important;
            font-size: 0.85rem !important; text-shadow: none !important; color: #f8f8f2 !important;
        }}

        /* Prism Token Overrides for Odin */
        .token.comment {{ color: var(--m-gray) !important; font-style: italic; }}
        .token.keyword, .token.operator {{ color: var(--m-pink) !important; }}
        .token.function {{ color: var(--m-green) !important; }}
        .token.string {{ color: var(--m-yellow) !important; }}
        .token.attr-name {{ color: var(--m-blue) !important; font-style: italic; }}
        .token.builtin {{ color: var(--m-blue) !important; }}
        .token.number {{ color: #ae81ff !important; }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>{p_title}</h1>
            <div class="tagline">{p_tagline}</div>
        </header>
        <input type="text" id="search" placeholder="Search API items...">
        <div id="api-root">{content}</div>
    </div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script>
        Prism.languages.odin = Prism.languages.extend('clike', {{
            'keyword': /\\b(?:package|import|proc|struct|enum|union|return|defer|if|else|for|case|switch|break|continue|dynamic|map|bit_set|typeid)\\b/,
            'operator': /->|::|:=|\\.\\.|[\\+\\-\\*\\/%=<>!&|\\^~]+/,
            'attr-name': /@\\w+/,
            'builtin': /\\b(?:u8|u16|u32|u64|i8|i16|i32|i64|f32|f64|bool|string|rawptr|any|int|uint)\\b/
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
    seen_names = set()
    lines = content.splitlines()
    pattern = re.compile(r"^(?P<name>\w+)\s*:\s*(?P<is_const>:)?")
    for i, line in enumerate(lines):
        match = pattern.match(line)
        if match:
            name = match.group("name")
            if name in seen_names or name in ["import", "package"]: continue
            comment_lines = []
            for j in range(i-1, -1, -1):
                prev = lines[j].strip()
                if prev.startswith("//") or prev.endswith("*/"): comment_lines.insert(0, lines[j])
                elif prev == "" or prev.startswith("/*"): continue
                else: break
            body_lines = []
            for k in range(i, len(lines)):
                body_lines.append(lines[k])
                if "{" in lines[k]:
                    full_text_from_here = "\n".join(lines[k:])
                    block = get_balanced_block(full_text_from_here, 0)
                    if block:
                        body_lines[-1] = block
                        break
                elif ";" in lines[k] or (k > i and lines[k].strip() == ""): break
            full_code = "\n".join(comment_lines + body_lines).strip()
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
            <span class="badge">{item['file']}</span>
            <span class="badge">{item['category']}</span></div></summary>
            <div class="content"><pre class="language-odin"><code class="language-odin">{safe_code}</code></pre></div>
        </details>"""
    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        f.write(HTML_TEMPLATE.format(content=html_output, p_title=PROJECT_TITLE, p_tagline=PROJECT_TAGLINE))

if __name__ == "__main__":
    parse()
