#!/usr/bin/env python3
"""Assembles the landing site.

Pages live in landing_src/pages as HTML fragments with a small front matter
block; partials (head, header, footer, docs sidebar) live in
landing_src/partials. The output goes to landing/<path>/index.html, which is
the folder uploaded to Hostinger as-is. Static assets (css, js, images,
.htaccess, robots.txt) are kept directly in landing/ and are not touched.

Also:
  * syntax-colours <pre data-lang="yaml|bash|groovy|kotlin"> blocks, so the
    sources stay plain text;
  * marks the active nav link and docs sidebar entry;
  * writes sitemap.xml.

    python3 tool/build_landing.py
"""
import html
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'landing_src'
OUT = ROOT / 'landing'
SITE = 'https://apprelease.store'
APP = 'https://publish.apprelease.store'
VERSION = '20261023'


def read(name):
    return (SRC / 'partials' / name).read_text(encoding='utf-8')


def front_matter(text):
    m = re.match(r'^---\n(.*?)\n---\n(.*)$', text, re.S)
    if not m:
        raise SystemExit('missing front matter')
    meta = {}
    for line in m.group(1).splitlines():
        k, _, v = line.partition(':')
        meta[k.strip()] = v.strip()
    return meta, m.group(2)


# ------------------------------------------------------------ highlighting

def hl_yaml(code):
    out = []
    for line in code.split('\n'):
        if line.strip().startswith('#'):
            out.append('<span class="c">%s</span>' % html.escape(line))
            continue
        head, sep, comment = line.partition(' #')
        m = re.match(r'^(\s*-?\s*)([\w./-]+)(:)(.*)$', head)
        if m and not head.strip().startswith('- ') or (m and ':' in head and not head.strip().startswith('-')):
            indent, key, colon, rest = m.groups()
            rest = hl_value(rest)
            piece = '%s<span class="k">%s</span>%s%s' % (html.escape(indent), html.escape(key), colon, rest)
        elif m:
            indent, key, colon, rest = m.groups()
            piece = '%s<span class="k">%s</span>%s%s' % (html.escape(indent), html.escape(key), colon, hl_value(rest))
        else:
            piece = hl_value(head)
        if sep:
            piece += '<span class="c">%s</span>' % html.escape(sep + comment)
        out.append(piece)
    return '\n'.join(out)


def hl_value(text):
    esc = html.escape(text)
    esc = re.sub(r'(&quot;[^&]*?&quot;|&#x27;[^&]*?&#x27;|"[^"]*"|\'[^\']*\')', r'<span class="s">\1</span>', esc)
    esc = re.sub(r'(\$\{?[A-Z_][A-Z0-9_]*\}?)', r'<span class="v">\1</span>', esc)
    esc = re.sub(r'(?<![\w"\'-])(\d+(?:\.\d+)*|true|false|null)(?![\w"\'-])', r'<span class="n">\1</span>', esc)
    return esc


def hl_bash(code):
    out = []
    for line in code.split('\n'):
        esc = html.escape(line)
        if line.strip().startswith('#'):
            out.append('<span class="c">%s</span>' % esc)
            continue
        esc = re.sub(r'(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?)', r'<span class="v">\1</span>', esc)
        esc = re.sub(r'(&quot;[^&]*?&quot;|"[^"]*")', r'<span class="s">\1</span>', esc)
        esc = re.sub(r'(\s)(--?[\w-]+)', r'\1<span class="k">\2</span>', esc)
        out.append(esc)
    return '\n'.join(out)


def hl_code(code):  # groovy / kotlin / dart: strings, comments, a few keywords
    esc = html.escape(code)
    esc = re.sub(r'(//.*)$', r'<span class="c">\1</span>', esc, flags=re.M)
    esc = re.sub(r'(&quot;[^&]*?&quot;|"[^"\n]*"|\'[^\'\n]*\')', r'<span class="s">\1</span>', esc)
    esc = re.sub(r'\b(android|signingConfigs|buildTypes|release|defaultConfig|val|if|else|file|System|getenv|storeFile|storePassword|keyAlias|keyPassword|signingConfig)\b', r'<span class="k">\1</span>', esc)
    return esc


def highlight(body):
    def repl(m):
        lang, attrs, code = m.group(1), m.group(2), m.group(3)
        code = code.strip('\n')
        if lang == 'yaml':
            inner = hl_yaml(code)
        elif lang == 'bash':
            inner = hl_bash(code)
        elif lang in ('groovy', 'kotlin', 'dart'):
            inner = hl_code(code)
        else:
            inner = html.escape(code)
        return '<pre data-lang="%s"%s><code>%s</code></pre>' % (lang, attrs, inner)
    return re.sub(r'<pre data-lang="(\w+)"([^>]*)>\n?(.*?)</pre>', repl, body, flags=re.S)


# ---------------------------------------------------------------- assembly

def build_page(src):
    meta, body = front_matter(src.read_text(encoding='utf-8'))
    path = meta['path']
    layout = meta.get('layout', 'marketing')
    body = highlight(body)

    head = read('head.html')
    header = read('header.html')
    footer = read('footer.html')

    nav = meta.get('nav', '')
    header = re.sub(r'data-nav="%s"' % re.escape(nav), 'data-nav="%s" class="is-active"' % nav, header) if nav else header

    if layout == 'docs':
        side = read('docs_sidebar.html')
        side = side.replace('href="%s"' % path, 'href="%s" class="is-active"' % path)
        crumbs = meta.get('crumbs', '')
        crumb_html = ''
        if crumbs:
            parts = [p.strip() for p in crumbs.split('>')]
            crumb_html = '<nav class="crumbs" aria-label="Breadcrumb"><a href="/docs/">Docs</a>'
            for p in parts:
                crumb_html += ' <span>›</span> <span>%s</span>' % html.escape(p)
            crumb_html += '</nav>'
        toc = '<aside class="docs-toc"><h4>On this page</h4><ol></ol></aside>' if meta.get('toc', 'true') == 'true' else ''
        main = ('<main id="main"><div class="wrap docs-layout">'
                '<div class="docs-side"><button type="button" class="docs-side-toggle">Documentation</button>'
                '<nav class="docs-nav" aria-label="Documentation">%s</nav></div>'
                '<article class="docs-article">%s%s</article>%s</div></main>') % (side, crumb_html, body, toc)
        body_class = ' class="docs-page"'
        extra_css = '\n<link rel="stylesheet" href="/docs.css?v=%s">' % VERSION
        header = header.replace('<!--docs-search-->', read('docs_search.html'))
    else:
        main = '<main id="main">%s</main>' % body
        body_class = ''
        extra_css = ''

    title = meta['title']
    desc = meta['description']
    page = head
    for k, v in {
        '{{title}}': html.escape(title),
        '{{description}}': html.escape(desc, quote=True),
        '{{canonical}}': SITE + path,
        '{{extra_css}}': extra_css,
        '{{version}}': VERSION,
        '{{body_class}}': body_class,
    }.items():
        page = page.replace(k, v)
    page = page + header + main + footer + '\n<script src="/app.js?v=%s"></script>\n</body>\n</html>\n' % VERSION
    page = page.replace('{{app}}', APP).replace('{{site}}', SITE)

    target = OUT / path.strip('/') / 'index.html' if path != '/' else OUT / 'index.html'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(page, encoding='utf-8')
    return path, meta.get('priority', '0.6')


def main():
    pages = sorted(SRC.glob('pages/**/*.html'))
    entries = [build_page(p) for p in pages]
    sitemap = ['<?xml version="1.0" encoding="UTF-8"?>',
               '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for path, prio in sorted(entries):
        sitemap.append('  <url><loc>%s%s</loc><priority>%s</priority></url>' % (SITE, path, prio))
    sitemap.append('</urlset>')
    (OUT / 'sitemap.xml').write_text('\n'.join(sitemap) + '\n', encoding='utf-8')
    print('built %d pages' % len(entries))


if __name__ == '__main__':
    sys.exit(main())
