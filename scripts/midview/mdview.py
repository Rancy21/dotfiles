#!/usr/bin/env python3
"""
mdview.py - View Markdown files in your browser.

Usage:
    python3 mdview.py <path-to-markdown-file>

Install markdown module for full GFM support:
    pip install markdown
"""

import sys
import os
import re
import tempfile
import webbrowser
import urllib.parse
from pathlib import Path


def escape_html(text):
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    return text


def get_pygments_css():
    """Generate Pygments CSS for light and dark mode. Returns '' if unavailable."""
    try:
        from pygments.formatters import HtmlFormatter
        from pygments.styles import get_style_by_name

        light_css = HtmlFormatter(style='default').get_style_defs('.codehilite')

        dark_style = 'monokai'
        try:
            get_style_by_name('github-dark')
            dark_style = 'github-dark'
        except Exception:
            pass
        # Use same class name; dark rules override light inside @media block
        dark_css = HtmlFormatter(style=dark_style).get_style_defs('.codehilite')

        return f"""
    {light_css}
    @media (prefers-color-scheme: dark) {{
        {dark_css}
    }}"""
    except ImportError:
        return ""


def highlight_code(code, lang):
    """Return Pygments-highlighted HTML, or None if unavailable."""
    try:
        from pygments import highlight
        from pygments.lexers import get_lexer_by_name, guess_lexer
        from pygments.formatters import HtmlFormatter
        from pygments.util import ClassNotFound

        if lang:
            try:
                lexer = get_lexer_by_name(lang, stripnl=False)
            except ClassNotFound:
                # Lang not recognised — try guessing, then fall back to plain text
                lexer = None
        else:
            lexer = None

        if lexer is None:
            try:
                lexer = guess_lexer(code)
            except ClassNotFound:
                return None

        formatter = HtmlFormatter(cssclass='codehilite', noclasses=False)
        return highlight(code, lexer, formatter)
    except ImportError:
        return None


def simple_md_to_html(text):
    """Basic markdown-to-html converter using regex (no external deps)."""
    text = text.replace("\r\n", "\n")
    lines = text.split("\n")
    html_lines = []
    in_code_block = False
    code_lang = ""
    code_lines = []
    in_list = False
    list_type = ""  # 'ul' or 'ol'
    list_items = []

    def flush_list():
        nonlocal in_list, list_type, list_items
        if in_list:
            tag = list_type
            items = "\n".join(f"<li>{item}</li>" for item in list_items)
            html_lines.append(f"<{tag}>\n{items}\n</{tag}>")
            in_list = False
            list_items = []

    def flush_code():
        nonlocal in_code_block, code_lang, code_lines
        if in_code_block:
            code_raw = "\n".join(code_lines)
            highlighted = highlight_code(code_raw, code_lang)
            if highlighted:
                # Pygments output includes its own <pre> wrapper
                html_lines.append(highlighted)
            else:
                lang = f' class="language-{escape_html(code_lang)}"' if code_lang else ""
                code_content = escape_html(code_raw)
                html_lines.append(f'<pre><code{lang}>{code_content}</code></pre>')
            in_code_block = False
            code_lang = ""
            code_lines = []

    def inline_format(line):
        # code span
        line = re.sub(r'`([^`]+)`', r'<code>\1</code>', line)
        # bold/italic
        line = re.sub(r'\*\*\*(.+?)\*\*\*', r'<em><strong>\1</strong></em>', line)
        line = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', line)
        line = re.sub(r'\*(.+?)\*', r'<em>\1</em>', line)
        line = re.sub(r'___(.+?)___', r'<em><strong>\1</strong></em>', line)
        line = re.sub(r'__(.+?)__', r'<strong>\1</strong>', line)
        line = re.sub(r'_(.+?)_', r'<em>\1</em>', line)
        # strikethrough
        line = re.sub(r'~~(.+?)~~', r'<del>\1</del>', line)
        # links
        line = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', line)
        # images
        line = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', r'<img src="\2" alt="\1" />', line)
        return line

    i = 0
    while i < len(lines):
        line = lines[i]

        # code block
        if line.startswith("```"):
            flush_list()
            if not in_code_block:
                in_code_block = True
                code_lang = line[3:].strip()
            else:
                flush_code()
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # horizontal rule
        if re.match(r'^(---+|===+|___+|\*\*\*+)\s*$', line):
            flush_list()
            html_lines.append("<hr />")
            i += 1
            continue

        # empty line
        if line.strip() == "":
            flush_list()
            html_lines.append("")
            i += 1
            continue

        # headings
        m = re.match(r'^(#{1,6})\s+(.*)$', line)
        if m:
            flush_list()
            level = len(m.group(1))
            content = inline_format(m.group(2))
            html_lines.append(f'<h{level}>{content}</h{level}>')
            i += 1
            continue

        # blockquote
        if line.startswith(">"):
            flush_list()
            quote_lines = []
            while i < len(lines) and lines[i].startswith(">"):
                quote_lines.append(lines[i][1:].lstrip())
                i += 1
            quote_html = simple_md_to_html("\n".join(quote_lines))
            html_lines.append(f'<blockquote>\n{quote_html}\n</blockquote>')
            continue

        # unordered list
        m = re.match(r'^(\s*)([-*+])\s+(.*)$', line)
        if m:
            indent = len(m.group(1))
            if in_list and list_type != "ul":
                flush_list()
            if not in_list:
                in_list = True
                list_type = "ul"
            list_items.append(inline_format(m.group(3)))
            i += 1
            continue

        # ordered list
        m = re.match(r'^(\s*)\d+\.\s+(.*)$', line)
        if m:
            if in_list and list_type != "ol":
                flush_list()
            if not in_list:
                in_list = True
                list_type = "ol"
            list_items.append(inline_format(m.group(2)))
            i += 1
            continue

        # paragraph
        flush_list()
        para_lines = [line]
        while i + 1 < len(lines) and lines[i + 1].strip() != "":
            i += 1
            para_lines.append(lines[i])
        para = inline_format(" ".join(para_lines))
        html_lines.append(f"<p>{para}</p>")
        i += 1

    flush_list()
    flush_code()
    return "\n".join(html_lines)


def md_to_html(text):
    try:
        import markdown
        extensions = ['extra', 'codehilite', 'toc']
        available = []
        for ext in extensions:
            try:
                markdown.markdown('', extensions=[ext])
                available.append(ext)
            except Exception:
                pass
        return markdown.markdown(text, extensions=available)
    except ImportError:
        return simple_md_to_html(text)


HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<style>
  :root {{
    --bg: #ffffff;
    --fg: #24292f;
    --border: #d0d7de;
    --code-bg: #f6f8fa;
    --blockquote-fg: #57606a;
    --link: #0969da;
    --link-hover: #0550ae;
  }}
  @media (prefers-color-scheme: dark) {{
    :root {{
      --bg: #0d1117;
      --fg: #c9d1d9;
      --border: #30363d;
      --code-bg: #161b22;
      --blockquote-fg: #8b949e;
      --link: #58a6ff;
      --link-hover: #79c0ff;
    }}
  }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    line-height: 1.6;
    color: var(--fg);
    background: var(--bg);
    max-width: 900px;
    margin: 40px auto;
    padding: 0 24px;
  }}
  h1, h2, h3, h4, h5, h6 {{
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    font-weight: 600;
    line-height: 1.25;
  }}
  h1 {{ border-bottom: 1px solid var(--border); padding-bottom: 0.3em; font-size: 2em; }}
  h2 {{ border-bottom: 1px solid var(--border); padding-bottom: 0.3em; font-size: 1.5em; }}
  a {{ color: var(--link); text-decoration: none; }}
  a:hover {{ color: var(--link-hover); text-decoration: underline; }}
  code {{
    font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
    background: var(--code-bg);
    padding: 0.2em 0.4em;
    border-radius: 6px;
    font-size: 85%;
  }}
  pre {{
    background: var(--code-bg);
    padding: 16px;
    border-radius: 8px;
    overflow-x: auto;
    line-height: 1.45;
  }}
  pre code {{ padding: 0; background: transparent; }}
  blockquote {{
    margin: 0;
    padding-left: 1em;
    border-left: 0.25em solid var(--border);
    color: var(--blockquote-fg);
  }}
  img {{ max-width: 100%; height: auto; }}
  table {{
    border-collapse: collapse;
    width: 100%;
    margin: 1em 0;
  }}
  th, td {{ border: 1px solid var(--border); padding: 6px 13px; }}
  th {{ background: var(--code-bg); }}
  ul, ol {{ padding-left: 1.5em; }}
  hr {{ border: none; border-top: 1px solid var(--border); margin: 1.5em 0; }}
{pygments_css}
  .codehilite {{ background: var(--code-bg); border-radius: 8px; overflow-x: auto; padding: 16px; }}
  .codehilite pre {{ padding: 0; margin: 0; background: transparent; }}
</style>
</head>
<body>
{content}
</body>
</html>
"""


def main():
    if len(sys.argv) < 2:
        print("Usage: mdview.py <path-to-markdown-file>")
        sys.exit(1)

    md_path = Path(sys.argv[1]).expanduser().resolve()
    if not md_path.exists():
        print(f"Error: File not found: {md_path}")
        sys.exit(1)

    text = md_path.read_text(encoding="utf-8")
    body_html = md_to_html(text)

    title = md_path.name
    pygments_css = get_pygments_css()
    html = HTML_TEMPLATE.format(title=title, content=body_html, pygments_css=pygments_css)

    # Write to temp file next to original for relative image paths to work
    # But if we can't, fall back to system temp
    try:
        out_path = md_path.with_suffix(".mdview.html")
        out_path.write_text(html, encoding="utf-8")
    except PermissionError:
        fd, tmp = tempfile.mkstemp(suffix=".mdview.html", prefix=md_path.stem + "_")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(html)
        out_path = Path(tmp)

    url = out_path.as_uri()
    print(f"Opening: {url}")
    webbrowser.open(url)


if __name__ == "__main__":
    main()
