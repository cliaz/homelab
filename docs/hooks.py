"""MkDocs hooks for the homelab docs site.

Stack pages under docs/stacks/ are thin wrappers that include each stack
folder's README.md / INSTALL.md, so the stack folders stay the single source
of truth. These hooks smooth over the differences between GitHub's markdown
rendering and MkDocs':
  - lists directly under a line of text (no blank line) render as lists, as on GitHub
  - links between README.md and INSTALL.md point at the site pages
  - "Edit this page" opens the real source file, not the wrapper
  - images link to the full-size file, so the big diagrams can be opened and zoomed
"""
import re

# wrapper page -> source file, read from the include directive in the wrapper
INCLUDE_RE = re.compile(r'{%\s*include-markdown\s+"\.\./\.\./\.\./([^"]+)"')
LIST_ITEM_RE = re.compile(r"^\s*([-*+]|\d+\.)\s")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
IMG_RE = re.compile(r'(<a\b[^>]*>\s*)?(<img\b[^>]*\bsrc="([^"]+)"[^>]*>)')


def _loosen_lists(markdown):
    """Insert a blank line before a list that directly follows a paragraph line."""
    out, in_fence, prev = [], False, ""
    for line in markdown.split("\n"):
        if FENCE_RE.match(line):
            in_fence = not in_fence
        elif not in_fence and LIST_ITEM_RE.match(line) and prev.strip() \
                and not LIST_ITEM_RE.match(prev) and not prev.startswith(("|", "#", ">", " ")):
            out.append("")
        out.append(line)
        prev = line
    return "\n".join(out)


def on_page_markdown(markdown, page, config, files):
    markdown = _loosen_lists(markdown)
    if page.file.src_uri.startswith("stacks/"):
        markdown = re.sub(r"\]\(\./INSTALL\.md\)", "](install.md)", markdown)
        markdown = re.sub(r"\]\(\./README\.md\)", "](index.md)", markdown)
    return markdown


def on_page_content(html, page, config, files):
    def link(m):
        if m.group(1):  # already inside a link
            return m.group(0)
        return f'<a href="{m.group(3)}" target="_blank">{m.group(2)}</a>'
    return IMG_RE.sub(link, html)


def on_page_context(context, page, config, nav):
    if page.file.src_uri.startswith("stacks/"):
        with open(page.file.abs_src_path, encoding="utf-8") as f:
            m = INCLUDE_RE.search(f.read())
        if m:
            page.edit_url = f"{config['repo_url'].rstrip('/')}/edit/main/{m.group(1)}"
    return context
