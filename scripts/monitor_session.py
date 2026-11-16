#!/usr/bin/env python3
"""Read My Paladin traces without executing SavedVariables or changing game files."""
import argparse
from collections import Counter, OrderedDict
import json
import math
from pathlib import Path
import re
import time

PREFIX = "MPALADIN1|"
LUA_STRING = re.compile(r'"(?:\\.|[^"\\])*"')
MAX_READ = 2 * 1024 * 1024
ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GAME = Path.home() / "Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_"


def records(line, saved=False):
    if PREFIX not in line:
        return
    candidates = []
    if saved:
        for token in LUA_STRING.findall(line):
            if PREFIX in token:
                try:
                    candidates.append(json.loads(token))
                except (ValueError, TypeError):
                    continue
    else:
        candidates.append(line[line.index(PREFIX):])
    for candidate in candidates:
        if not candidate.startswith(PREFIX):
            continue
        try:
            record, _ = json.JSONDecoder().raw_decode(candidate[len(PREFIX):])
        except ValueError:
            continue
        if not isinstance(record, dict) or record.get("schema") != 1:
            continue
        if not isinstance(record.get("session"), str) or not re.fullmatch(r"\d+-\d+", record["session"]):
            continue
        if type(record.get("seq")) is not int or record["seq"] < 1:
            continue
        if not all(isinstance(record.get(key), str) and re.fullmatch(r"[A-Za-z_]+", record[key])
                   for key in ("feature", "state")):
            continue
        if any(type(value) is float and not math.isfinite(value) for value in record.values()):
            continue
        # Export only the recorder's public fields, even if a source contains extra data.
        yield {key: value for key, value in record.items()
               if key in {"schema", "session", "seq", "uptime", "feature", "state", "spell", "count",
                          "detail", "profile", "mode", "combat"}
               and type(value) in (str, int, bool, float)}


class Monitor:
    def __init__(self, game):
        self.game = Path(game)
        self.positions = {}
        self.events = OrderedDict()
        self.live_seen = False

    def poll(self):
        paths = list((self.game / "Logs").glob("*.log"))
        paths += list((self.game / "WTF").glob("**/SavedVariables/MyPaladin.lua"))
        new = []
        for path in paths:
            try:
                stat = path.stat()
                previous = self.positions.get(path)
                stamp = (stat.st_ino, stat.st_size, stat.st_mtime_ns)
                if previous and previous[0] == stamp:
                    continue
                saved = path.name == "MyPaladin.lua"
                offset, pending = (0, b"")
                if not saved and previous and previous[0][0] == stat.st_ino and stat.st_size > previous[0][1]:
                    offset, pending = previous[1:]
                if stat.st_size - offset > MAX_READ:
                    offset, pending = stat.st_size - MAX_READ, b""
                with path.open("rb") as handle:
                    handle.seek(offset)
                    content = pending + handle.read(MAX_READ)
                    offset = handle.tell()
                lines = content.split(b"\n")
                pending = b"" if saved else lines.pop()[-MAX_READ:]
                self.positions[path] = (stamp, offset, pending)
                for line in lines:
                    for record in records(line.decode("utf-8", errors="replace"), saved):
                        if not saved:
                            self.live_seen = True
                        key = (record["session"], record["seq"])
                        if key not in self.events:
                            self.events[key] = record
                            new.append(record)
                            if len(self.events) > 5000:
                                self.events.popitem(last=False)
            except OSError as error:
                print(f"Read failed: {path.name}: {error.strerror}")
        return new

    def report(self):
        events = sorted(self.events.values(), key=lambda e: (tuple(map(int, e["session"].split("-"))), e["seq"]))
        lines = ["# My Paladin — diagnóstico", "",
                 f"Registros disponíveis: {len(events)} (máximo 5000 no monitor; 1000 no addon).",
                 "Transporte: " + ("C_Log encontrado em disco; confira a idade dos registros para avaliar latência."
                                    if self.live_seen else "C_Log não observado em disco; use /reload ou saia normalmente."),
                 "", "Uma decisão registrada não prova execução, dano ou posição visível na tela.",
                 "O monitor lê só traces do addon; erros anteriores ao carregamento exigem o erro nativo do jogo.",
                 "Logs nativos começam nos últimos 2 MiB; arquivos sem mudança não são relidos.", ""]
        counts = Counter((e["feature"], e["state"]) for e in events)
        for feature in ("session", "config", "seal_hud", "combat_hint", "estimate", "bindings", "action_binding", "mana", "cast", "error", "marker"):
            states = [f"{state} ({count})" for (name, state), count in sorted(counts.items()) if name == feature]
            lines.append(f"- {feature}: " + (", ".join(states) if states else "não observado"))
        lines += ["", "## Acesso às APIs observado", "",
                  "`restricted`: dado protegido; `api_missing`: API ausente; `call_failed`: chamada falhou (causa não confirmada).",
                  "`invalid`: retorno inesperado; `not_checked`: consulta dispensada/adiada pelo addon.",
                  "`public`, `present`, `missing`: leitura pública; `native_only`: apenas exibição no widget, sem ler prontidão.",
                  "`call_accepted`: C_Log aceitou a chamada; não comprova entrega em disco.",
                  "Estados abaixo são evidências históricas nesta captura, não permissões garantidas para outras situações.", "",
                  "| Verificação | Fora de combate | Em combate | Motivo da última limitação (ou leitura) |",
                  "| --- | --- | --- | --- |"]
        probes = sorted({e["feature"] for e in events if e["feature"].startswith("api_")})
        for feature in probes:
            observations = [e for e in events if e["feature"] == feature]
            cells = []
            for combat in (False, True):
                states = sorted({e["state"] for e in observations if e.get("combat") is combat})
                cells.append(", ".join(states) or "não observado")
            limits = [e for e in observations if e["state"] in {"restricted", "api_missing", "call_failed", "invalid", "unavailable"}]
            detail = str((limits or observations)[-1].get("detail", "")).replace("|", "\\|").replace("\n", " ")
            lines.append(f"| {feature} | {cells[0]} | {cells[1]} | {detail} |")
        if not probes:
            lines += ["| Sem diagnóstico detalhado nesta captura | não observado | não observado | Requer 0.8.1 ou posterior |"]
        issues = []
        for event in events:
            state, count = event["state"], event.get("count")
            if event["feature"] == "seal_hud" and state in {"echo_build", "echo_swap", "echo_wait", "echo_return"}:
                valid = type(count) is int and {
                    "echo_build": count in (0, 1), "echo_swap": count in (2, 3),
                    "echo_wait": count in (1, 2, 3), "echo_return": count == 0,
                }[state]
                if not valid:
                    issues.append(f"{event['session']} #{event['seq']}: {state} count={count}")
        lines += ["", f"Inconsistências na contagem de ecos: {len(issues)}."]
        lines += ["- " + text for text in issues[:20]]
        lines += ["", "## Últimos registros", "", "```jsonl"]
        lines += [json.dumps(e, ensure_ascii=True, allow_nan=False) for e in events[-30:]]
        lines += ["```", "", "Não observado significa sem evidência nesta captura; não equivale a aprovado.", ""]
        return "\n".join(lines), events

    def write_report(self, output):
        output = Path(output)
        output.mkdir(parents=True, exist_ok=True, mode=0o700)
        report, events = self.report()
        for name, content in (("report.md", report), ("events.jsonl", "".join(
                json.dumps(e, ensure_ascii=True, allow_nan=False) + "\n" for e in events))):
            temporary = output / (name + ".tmp")
            temporary.touch(mode=0o600)
            temporary.write_text(content)
            temporary.replace(output / name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-dir", type=Path, default=DEFAULT_GAME)
    parser.add_argument("--output", type=Path, default=ROOT / ".diagnostics")
    parser.add_argument("--watch", action="store_true", help="Poll every second; Ctrl+C stops")
    args = parser.parse_args()
    if not (args.game_dir / "WTF").is_dir():
        parser.error("--game-dir must point to the _forever_ directory with WTF/")
    monitor = Monitor(args.game_dir)
    try:
        first = True
        while True:
            was_live = monitor.live_seen
            new = monitor.poll()
            if first or new or was_live != monitor.live_seen:
                monitor.write_report(args.output)
                for event in new:
                    print(json.dumps(event, ensure_ascii=True), flush=True)
                print(f"Report: {args.output / 'report.md'} | C_Log observed: {monitor.live_seen}", flush=True)
            first = False
            if not args.watch:
                return
            time.sleep(1)
    except KeyboardInterrupt:
        monitor.write_report(args.output)


if __name__ == "__main__":
    main()
