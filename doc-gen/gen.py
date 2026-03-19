import os
import re

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
SOURCE_DIR = os.path.join(PROJECT_ROOT, "src")
OUTPUT_HTML = os.path.join(BASE_DIR, "index.html")
TEMPLATE_PATH = os.path.join(BASE_DIR, "template.html")

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
            cat = "PROC" if "proc" in rem else "STRUCT" if "struct" in rem else "ENUM" if "enum" in rem else None

            if cat:
                comments = []
                for j in range(i-1, -1, -1):
                    if lines[j].strip().startswith(("//", "/*")) or lines[j].strip().endswith("*/"):
                        comments.insert(0, lines[j])
                    elif lines[j].strip() == "": continue
                    else: break

                full_code = "\n".join(comments + body_lines).strip()
                results.append({"name": name, "category": cat, "code": full_code, "file": filename})
    return results

def generate():
    all_items = []
    for root, _, files in os.walk(SOURCE_DIR):
        for file in sorted(files):
            if file.endswith(".odin"):
                with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                    all_items.extend(extract_items(f.read(), file))

    cat_order = {"STRUCT": 1, "ENUM": 2, "PROC": 3}
    all_items.sort(key=lambda x: (x['file'], cat_order.get(x['category'], 4), x['name']))

    html_content, current_file = "", None
    for item in all_items:
        if item['file'] != current_file:
            if current_file: html_content += "</div>"
            current_file = item['file']
            html_content += f"<div class='file-section'><div class='file-header'>{current_file}</div>"

        safe_code = item['code'].replace("<", "&lt;").replace(">", "&gt;")
        html_content += f"""
        <details>
            <summary>{item['name']}<div class="badge">{item['category']}</div></summary>
            <div class="content"><pre class="language-odin"><code class="language-odin">{safe_code}</code></pre></div>
        </details>"""

    if current_file: html_content += "</div>"

    with open(TEMPLATE_PATH, "r") as f:
        template = f.read()

    final_html = template.replace("{{title}}", "Silicon Master API")\
                         .replace("{{tagline}}", "High-performance renderer technical reference.")\
                         .replace("{{content}}", html_content)

    with open(OUTPUT_HTML, "w", encoding="utf-8") as f:
        f.write(final_html)
    print(f"Documentation generated at {OUTPUT_HTML}")

if __name__ == "__main__":
    generate()
