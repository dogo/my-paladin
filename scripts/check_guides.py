#!/usr/bin/env python3
"""Compare guide content with the last manually accepted snapshots. Standard library only."""
import argparse
from datetime import datetime, timezone
import difflib
import fcntl
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import urljoin, urlsplit, urlunsplit
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
BASE = "https://www.wowhead.com/forever/guide/classes/paladin/retribution/"
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}
BLOCKS = {"p", "div", "section", "article", "h1", "h2", "h3", "h4", "h5", "li", "tr", "br"}
IGNORE = {"script", "style", "nav", "aside", "footer", "noscript"}


def guide_url(href):
    if not href or href.startswith("#"):
        return None
    url = urlsplit(urljoin("https://www.wowhead.com/forever/", href))
    if url.netloc == "www.wowhead.com" and re.match(r"/forever/guide(?:/|=)", url.path):
        return urlunsplit(("https", url.netloc, url.path, "", ""))
    return None


class ArticleParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.candidates = []
        self.heading = []
        self.modified = ""
        self.links = set()

    def append(self, text):
        if any(tag in IGNORE for tag in self.stack):
            return
        for candidate in self.candidates:
            if candidate["active"]:
                candidate["parts"].append(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "meta" and attrs.get("property") == "article:modified_time":
            self.modified = attrs.get("content", "")
        marker = attrs.get("id", "")
        rank = 0 if marker in {"guide-body", "guide-content"} else 1
        if marker in {"guide-body", "guide-content"} or tag == "article":
            if not any(t in IGNORE for t in self.stack):
                self.candidates.append({"depth": len(self.stack), "rank": rank, "active": True, "parts": []})
        if tag == "a" and any(c["active"] for c in self.candidates) and not any(t in IGNORE for t in self.stack):
            url = guide_url(attrs.get("href", ""))
            if url:
                self.links.add(url)
        if tag in BLOCKS:
            self.append("\n")
        if tag not in VOID:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if tag not in self.stack:
            return
        if tag in BLOCKS:
            self.append("\n")
        index = len(self.stack) - 1 - self.stack[::-1].index(tag)
        for candidate in self.candidates:
            if candidate["active"] and candidate["depth"] >= index:
                candidate["active"] = False
        del self.stack[index:]

    def handle_data(self, data):
        if "h1" in self.stack and not any(t in IGNORE for t in self.stack):
            self.heading.append(data)
        self.append(data)


def normalize(text):
    lines = []
    for line in text.splitlines():
        line = " ".join(line.split())
        if line in {"Comments", "Contribute"}:
            break
        if line:
            lines.append(line)
    return "\n".join(lines)


def normalize_markup(markup):
    markup = re.sub(r"\[nav(?:\s[^\]]*)?\].*?\[/nav\]", "", markup, flags=re.I | re.S)
    links = set()
    for href in re.findall(r'''(?:https?://www\.wowhead\.com/forever/|/forever/)?guide(?:=|/)[^\s\]"'<>]+''', markup):
        url = guide_url(href)
        if url:
            links.add(url)
    return normalize(markup), links


def extract_article(html):
    parser = ArticleParser()
    parser.feed(html)
    title = " ".join(" ".join(parser.heading).split())
    if not all(word in title.lower() for word in ("retribution", "paladin")):
        raise ValueError("Título do guia ausente: possível bloqueio, login ou página inesperada")
    candidates = sorted(parser.candidates, key=lambda c: (c["rank"], -len("".join(c["parts"]))))
    text = next((normalize("".join(c["parts"])) for c in candidates if len(normalize("".join(c["parts"]))) >= 500), "")
    if not text:
        # shortcut: only literal JSON strings are supported; fail if Wowhead changes its renderer.
        for match in re.finditer(r'markup\.printHtml\(\s*("(?:\\.|[^"\\])*")', html):
            try:
                markup = json.loads(match.group(1))
            except json.JSONDecodeError:
                continue
            if len(markup) >= 500 and "[h2" in markup:
                text, links = normalize_markup(markup)
                parser.links.update(links)
                break
    if len(text) < 500:
        raise ValueError("Corpo do guia não extraído; JavaScript/layout exige revisão do extrator")
    return {"title": title, "text": text, "modified": parser.modified, "links": sorted(parser.links)}


def fetch_article(url):
    request = Request(url, headers={"User-Agent": "MyPaladin-GuideCheck/0.2 (local change monitor)"})
    with urlopen(request, timeout=20) as response:
        if "text/html" not in response.headers.get("Content-Type", ""):
            raise ValueError("Resposta não é HTML")
        body = response.read(8 * 1024 * 1024 + 1)
        if len(body) > 8 * 1024 * 1024:
            raise ValueError("Resposta maior que 8 MiB")
        html = body.decode(response.headers.get_content_charset() or "utf-8")
    return extract_article(html)


def write_atomic(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(value, encoding="utf-8")
    temporary.replace(path)


def write_json(path, value):
    write_atomic(path, json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def load_state(folder):
    path = folder / "state.json"
    if path.exists():
        state = json.loads(path.read_text(encoding="utf-8"))
        # Apply the same normalization to both sides when upgrading the extractor.
        for key in ("reviewed", "latest"):
            for article in state[key].values():
                if "[h2" in article["text"]:
                    article["text"], links = normalize_markup(article["text"])
                    article["links"] = sorted(links | set(article.get("links", [])))
        return state
    return {"reviewed": {}, "latest": {}, "errors": {}}


def check(root=ROOT, fetch=fetch_article):
    config = json.loads((root / "guides.json").read_text(encoding="utf-8"))
    folder = root / ".guide-monitor"
    state = load_state(folder)
    state["errors"] = {}
    checked = datetime.now(timezone.utc).isoformat()
    report = ["# Checagem dos guias", "", f"Consulta: {checked}",
              f"Referência revisada: {config['reviewed_on']} — patch {config['patch']}", "",
              "Mudanças ficam pendentes até revisão e aceitação manual. Regras do addon não foram alteradas.", ""]
    pending = 0
    linked = set()
    for page in config["pages"]:
        slug = page["slug"]
        url = BASE + slug
        report.extend([f"## [{page['title']}]({url})", ""])
        try:
            latest = fetch(url)
            state["latest"][slug] = latest
            linked.update(latest.get("links", []))
        except Exception as error:
            message = f"{type(error).__name__}: {error}"
            state["errors"][slug] = message
            report.extend([f"**ERRO**: {message}", "Snapshot anterior preservado; página não considerada atualizada.", ""])
            continue
        reviewed = state["reviewed"].get(slug)
        if reviewed == latest:
            report.extend(["Sem mudanças desde a revisão aceita.", ""])
            continue
        pending += 1
        report.extend(["**REVISÃO PENDENTE**" if reviewed else "**PRIMEIRA CAPTURA — revisão pendente**",
                       f"Área a conferir: {page['impact']}.", ""])
        if reviewed:
            if reviewed.get("modified") != latest.get("modified"):
                report.append(f"Data da fonte: {reviewed.get('modified') or 'não informada'} → {latest.get('modified') or 'não informada'}")
            diff = list(difflib.unified_diff(reviewed["text"].splitlines(), latest["text"].splitlines(),
                                            fromfile="revisado", tofile="consultado", lineterm=""))
            excerpt = "\n".join(diff[:40])
            excerpt = " ".join(excerpt.split()[:180]) if len(excerpt.split()) > 180 else excerpt
            if excerpt:
                report.extend(["", "```diff", excerpt, "```", "Trecho limitado; compare os snapshots completos no state.json.", ""])
    unmonitored = sorted(linked - {BASE + page["slug"] for page in config["pages"]})
    if unmonitored:
        report.extend(["## Links de guias para conferir", "",
                       "Podem ser complementos ou aliases numéricos das fontes atuais. Conferir cobertura e fontes relevantes:", ""])
        report.extend(f"- {url}" for url in unmonitored)
    state["checked_at"] = checked
    state["pending"] = pending
    state["complete"] = not state["errors"] and len(state["latest"]) == len(config["pages"])
    status = "ERRO" if state["errors"] else "REVISÃO PENDENTE" if pending else "SEM MUDANÇAS"
    report.insert(2, f"Status: **{status}** — {pending} página(s) pendente(s), {len(state['errors'])} erro(s).")
    output = "\n".join(report) + "\n"
    write_json(folder / "state.json", state)
    write_atomic(folder / "report.md", output)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    write_atomic(folder / "history" / f"{stamp}.md", output)
    print(f"{status}: {pending} pendente(s), {len(state['errors'])} erro(s). Relatório: {folder / 'report.md'}")
    return 1 if state["errors"] else 2 if pending else 0


def accept(root=ROOT, patch=None):
    folder = root / ".guide-monitor"
    state = load_state(folder)
    config_path = root / "guides.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))
    expected = {page["slug"] for page in config["pages"]}
    if not state.get("complete") or state.get("errors") or set(state["latest"]) != expected:
        raise ValueError("Faça uma checagem completa sem erros antes de aceitar uma revisão")
    patch = patch or config["patch"]
    if not re.fullmatch(r"\d+\.\d+\.\d+", patch):
        raise ValueError("Patch deve ter o formato 1.60.1")
    config["reviewed_on"] = datetime.now(timezone.utc).date().isoformat()
    config["patch"] = patch
    state["reviewed"] = state["latest"].copy()
    state["pending"] = 0
    write_json(folder / "state.json", state)
    write_json(config_path, config)
    lua = ('local _, addon = ...\naddon.guideInfo = { reviewedOn = '
           + json.dumps(config["reviewed_on"]) + ', patch = ' + json.dumps(patch) + ' }\n')
    write_atomic(root / "MyPaladin" / "GuideInfo.lua", lua)
    write_atomic(folder / "report.md", "# Revisão aceita\n\n" + config["reviewed_on"]
                 + " — patch " + patch + "\n\nTodas as páginas capturadas foram aceitas manualmente.\n"
                 + "Ajuste as regras necessárias, rode os testes e publique/reinstale o addon.\n")
    print("Revisão aceita. Metadados atualizados; regras do addon não foram modificadas.")
    return 0


def notify_result(code, folder):
    program = shutil.which("notify-send")
    if code == 0 or not program:
        return
    title = "My Paladin: erro na consulta" if code == 1 else "My Paladin: guias aguardam revisão"
    try:
        subprocess.run([program, "--app-name=My Paladin", title, f"Relatório: {folder / 'report.md'}"],
                       timeout=5, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (OSError, subprocess.TimeoutExpired):
        pass  # Desktop notifications are optional; the report remains the authoritative result.


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--accept", action="store_true", help="Confirma que você revisou os snapshots e as regras afetadas")
    parser.add_argument("--patch", help="Patch revisado; usado somente com --accept")
    args = parser.parse_args()
    if args.patch and not args.accept:
        parser.error("--patch exige --accept")
    try:
        folder = ROOT / ".guide-monitor"
        folder.mkdir(parents=True, exist_ok=True)
        with (folder / "check.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            code = accept(patch=args.patch) if args.accept else check()
        if not args.accept:
            notify_result(code, folder)
        return code
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
