import os
import datetime

SOURCE_DIR = "src"
OUTPUT_DIR = "doc"
INDEX_FILE = os.path.join(OUTPUT_DIR, "index.html")

PROJECT_TITLE = "Silicon"
PROJECT_TAGLINE = "A high-performance OpenGL renderer written in Odin, supporting PBR and ray tracing for CAD visualization."

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Silicon Documentation</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
    <style>
        :root {{
            --bg: #0b0c0e;
            --card: #141619;
            --text: #abb2bf;
            --dim: #5c6370;
            --border: #21252b;
            --accent: #61afef;
            --code-bg: #1e2227;
        }}

        * {{ box-sizing: border-box; transition: background 0.2s, color 0.2s; }}
        body {{
            background: var(--bg); color: var(--text);
            font-family: 'Inter', -apple-system, sans-serif;
            margin: 0; display: flex; justify-content: center;
            padding: 40px 20px;
        }}

        .container {{ width: 100%; max-width: 1000px; display: grid; grid-template-columns: 240px 1fr; gap: 40px; }}

        .sidebar {{ position: sticky; top: 40px; height: fit-content; border-right: 1px solid var(--border); padding-right: 20px; }}
        .nav-header {{
            font-size: 0.8rem; font-weight: 900; color: #fff; letter-spacing: 3px;
            margin-bottom: 25px; cursor: pointer; text-transform: uppercase;
        }}
        .nav-header:hover {{ color: var(--accent); }}
        .nav-item {{
            display: block; font-size: 0.75rem; color: var(--dim);
            text-decoration: none; margin-bottom: 12px; font-family: 'JetBrains Mono', monospace;
            cursor: pointer;
        }}
        .nav-item:hover, .nav-item.active {{ color: var(--accent); padding-left: 8px; }}

        .main-card {{
            background: var(--card);
            border: 1px solid var(--border);
            padding: 45px;
            border-radius: 12px;
            min-height: 550px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.3);
        }}

        #home-view {{ text-align: center; padding-top: 50px; }}
        #home-view h2 {{ font-size: 3.5rem; color: #fff; margin: 0; letter-spacing: -1.5px; font-weight: 800; }}
        #home-view p {{ font-size: 1rem; color: var(--dim); max-width: 500px; margin: 20px auto 50px auto; line-height: 1.7; }}

        /* Powered By - Enhanced OpenGL & Odin Branding */
        .powered-by-label {{ font-size: 0.6rem; color: #3e4451; text-transform: uppercase; letter-spacing: 4px; margin-bottom: 25px; }}
        .powered-by {{ display: flex; justify-content: center; align-items: center; gap: 50px; margin-top: 30px; }}
        .brand-icon {{ display: flex; flex-direction: column; align-items: center; gap: 10px; color: var(--dim); }}
        .brand-icon:hover {{ color: var(--accent); }}
        .brand-icon span {{ font-family: 'JetBrains Mono'; font-weight: 900; font-size: 1.8rem; }}
        .brand-icon i {{ font-size: 2.2rem; }}
        .brand-icon label {{ font-size: 0.55rem; letter-spacing: 1px; font-weight: bold; opacity: 0.6; }}

        .file-content {{ display: none; }}
        .file-content.active {{ display: block; }}

        .file-badge {{
            font-family: monospace; font-size: 0.8rem; font-weight: bold;
            color: var(--accent); background: #1e2227; padding: 6px 14px; border-radius: 6px;
        }}
        .file-desc {{ font-size: 0.85rem; color: var(--dim); margin: 20px 0 40px 0; line-height: 1.7; border-left: 2px solid var(--border); padding-left: 20px; }}

        details {{ border-bottom: 1px solid var(--border); }}
        summary {{
            padding: 18px 10px; cursor: pointer; font-size: 0.85rem; font-weight: 500;
            display: flex; justify-content: space-between; align-items: center;
        }}
        summary:hover {{ background: #1c1f23; border-radius: 8px; }}
        details[open] summary {{ color: var(--accent); font-weight: 700; }}

        .proc-content {{ padding: 10px 0 30px 0; }}
        .proc-desc {{ font-size: 0.8rem; color: var(--dim); margin-bottom: 15px; font-style: italic; padding: 0 10px; }}

        pre {{ margin: 0 !important; padding: 25px !important; background: var(--code-bg) !important; border-radius: 8px !important; border: 1px solid #181a1f !important; }}
        code {{ font-family: 'JetBrains Mono', monospace !important; font-size: 0.82rem !important; line-height: 1.6 !important; }}

        /* --- ONE DARK PRO SYNTAX HIGHLIGHTING --- */
        .token.comment, .token.prolog, .token.doctype, .token.cdata {{ color: #5c6370; font-style: italic; }}
        .token.punctuation {{ color: #abb2bf; }}
        .token.namespace {{ opacity: .7; }}
        .token.property, .token.tag, .token.constant, .token.symbol, .token.deleted {{ color: #e06c75; }}
        .token.boolean, .token.number {{ color: #d19a66; }}
        .token.selector, .token.attr-name, .token.string, .token.char, .token.builtin, .token.inserted {{ color: #98c379; }}
        .token.operator, .token.entity, .token.url, .language-css .token.string, .style .token.string, .token.variable {{ color: #56b6c2; }}
        .token.atrule, .token.attr-value, .token.function {{ color: #61afef; }}
        .token.keyword {{ color: #c678dd; }}
        .token.regex, .token.important {{ color: #e06c75; }}
    </style>
</head>
<body>
    <div class="container">
        <aside class="sidebar">
            <div class="nav-header" onclick="showHome()">Silicon Doc</div>
            <div id="nav-list">{nav_links}</div>
        </aside>

        <div class="main-card">
            <div id="home-view">
                <h2>{p_title}</h2>
                <p>{p_tagline}</p>

                <div class="powered-by-label">Powered By</div>
                <div class="powered-by">
                    <div class="brand-icon">
                        <span>ODIN</span>
                        <label>LANGUAGE</label>
                    </div>
                    <div class="brand-icon">
                        <i class="fas fa-cube"></i>
                        <label>OPENGL CORE</label>
                    </div>
                </div>

                <div style="font-size: 0.6rem; color: #282c34; margin-top: 100px; font-family: monospace; letter-spacing: 3px;">REF_DATA // {date}</div>
            </div>

            <div id="file-display">
                {content}
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
    <script>
        function showFile(fileId, event) {{
            document.getElementById('home-view').style.display = 'none';
            document.querySelectorAll('.file-content').forEach(f => f.classList.remove('active'));
            const target = document.getElementById('view-' + fileId);
            if (target) target.classList.add('active');
            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
            if (event) event.target.classList.add('active');
            window.scrollTo({{ top: 0, behavior: 'smooth' }});
        }}

        function showHome() {{
            document.getElementById('home-view').style.display = 'block';
            document.querySelectorAll('.file-content').forEach(f => f.classList.remove('active'));
            document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        }}
    </script>
</body>
</html>
"""

def capture_block(lines, start_idx):
    block, braces, started = [], 0, False
    for i in range(start_idx, len(lines)):
        line = lines[i]
        block.append(line)
        braces += line.count('{')
        braces -= line.count('}')
        if '{' in line: started = True
        if started and braces <= 0: break
    return "".join(block).rstrip()

def parse():
    now = datetime.datetime.now().strftime("%y.%m.%d")
    full_html, nav_links = "", ""

    if not os.path.exists(SOURCE_DIR): return

    for root, _, files in os.walk(SOURCE_DIR):
        for file in sorted(files):
            if not file.endswith(".odin"): continue
            with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                lines = f.readlines()

            file_explanation = []
            for line in lines:
                if "package" in line: break
                clean = line.replace("/*", "").replace("*/", "").replace("*", "").strip()
                if clean: file_explanation.append(clean)

            file_id = file.replace(".", "-")
            nav_links += f'<div class="nav-item" onclick="showFile(\'{file_id}\', event)">> {file}</div>'

            full_html += f"<div class='file-content' id='view-{file_id}'>"
            full_html += f"<span class='file-badge'>{file}</span>"
            desc = " ".join(file_explanation) if file_explanation else "Source file."
            full_html += f"<p class='file-desc'>{desc}</p>"

            i = 0
            while i < len(lines):
                if lines[i].strip().startswith("/*"):
                    comment_block, curr = [], i
                    while curr < len(lines):
                        c_line = lines[curr].replace("/*", "").replace("*/", "").replace("*", "").strip()
                        if c_line: comment_block.append(c_line)
                        if "*/" in lines[curr]: break
                        curr += 1

                    look = curr + 1
                    while look < len(lines) and not lines[look].strip(): look += 1

                    if look < len(lines) and ":: proc" in lines[look]:
                        name = lines[look].split("::")[0].strip()
                        full_code = capture_block(lines, look)
                        safe_code = full_code.replace("<", "&lt;").replace(">", "&gt;")

                        full_html += f"""
                        <details>
                            <summary>{name}</summary>
                            <div class="proc-content">
                                <div class="proc-desc">{" ".join(comment_block)}</div>
                                <pre><code class="language-clike">{safe_code}</code></pre>
                            </div>
                        </details>"""
                        i = look + len(full_code.splitlines())
                        continue
                i += 1
            full_html += "</div>"

    if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)
    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        f.write(HTML_TEMPLATE.format(
            date=now,
            content=full_html,
            nav_links=nav_links,
            p_title=PROJECT_TITLE,
            p_tagline=PROJECT_TAGLINE
        ))

if __name__ == "__main__":
    parse()
    print(f"Documentation generated: {INDEX_FILE}")
