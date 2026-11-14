import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("check_guides", ROOT / "scripts/check_guides.py")
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)


def page(body=None, extra=""):
    body = body or ("<p>Keep your seal active and save mana for useful spells.</p>" * 16)
    return ("<html><head><meta property='article:modified_time' content='2026-11-14'></head>"
            "<body><nav>Menu changes should not count</nav><h1>Retribution Paladin DPS Guide</h1>"
            "<div id='guide-body'>" + body + "<h2>Comments</h2><p>Unrelated comment</p></div>"
            + extra + "</body></html>")


class ExtractionTests(unittest.TestCase):
    def test_ignores_navigation_comments_and_scripts(self):
        first = monitor.extract_article(page())
        second = monitor.extract_article(page(extra="<script>advertisement_changed=1</script><aside>Ad</aside>"))
        self.assertEqual(first, second)
        self.assertNotIn("Unrelated comment", first["text"])
        self.assertNotIn("Menu", first["text"])
        self.assertEqual(first["modified"], "2026-11-14")

    def test_keeps_subsections_tables_and_link_inventory(self):
        body = ("<h2>Single target</h2><p>" + "Seal mechanics. " * 40
                + "</p><h2>AoE</h2><table><tr><td>Consecration</td><td>Mana</td></tr></table>"
                + "<a href='/forever/guide/classes/paladin/retribution/level-20-dps-overview#rotation'>Level 20</a>"
                + "<a href='#aoe'>AoE anchor</a><a href='https://example.org/guide/fake'>Other site</a>")
        result = monitor.extract_article(page(body))
        self.assertIn("AoE", result["text"])
        self.assertIn("Consecration", result["text"])
        self.assertEqual(result["links"], [monitor.BASE + "level-20-dps-overview"])

    def test_rejects_challenge_empty_and_comment_only_pages(self):
        for html in ("<h1>Just a moment</h1>", "<h1>Retribution Paladin</h1>",
                     "<h1>Retribution Paladin</h1><div class='text'>" + "A comment. " * 100 + "</div>"):
            with self.assertRaises(ValueError):
                monitor.extract_article(html)

    def test_literal_markup_fallback_does_not_execute_javascript(self):
        markup = ("[nav][nav-item=guide/classes/paladin/retribution/overview-pve-dps]Menu[/nav-item][/nav]"
                  + "[h2]Rotation[/h2]" + "Keep your seal active. " * 40
                  + '[cta href="guide=34796"]Camping[/cta][talent=paladin/example]')
        html = "<h1>Retribution Paladin</h1><script>WH.markup.printHtml(" + json.dumps(markup) + ");</script>"
        article = monitor.extract_article(html)
        self.assertIn("Rotation", article["text"])
        self.assertNotIn("Menu", article["text"])
        self.assertIn("[talent=paladin/example]", article["text"])
        self.assertEqual(article["links"], ["https://www.wowhead.com/forever/guide=34796"])


class MonitorTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.config = json.loads((ROOT / "guides.json").read_text())
        (self.root / "guides.json").write_text(json.dumps(self.config))
        (self.root / "MyPalladin").mkdir()
        self.rules = self.root / "MyPalladin/Profiles.lua"
        self.rules.write_text("original rules")
        self.original = monitor.extract_article(page())
        self.fetch = lambda url: self.original.copy()

    def state(self):
        return json.loads((self.root / ".guide-monitor/state.json").read_text())

    def test_first_capture_requires_acceptance_and_does_not_stamp_review(self):
        self.assertEqual(monitor.check(self.root, self.fetch), 2)
        state = self.state()
        self.assertEqual(len(state["latest"]), 8)
        self.assertEqual(state["reviewed"], {})
        self.assertEqual(json.loads((self.root / "guides.json").read_text()), self.config)
        self.assertFalse((self.root / "MyPalladin/GuideInfo.lua").exists())
        self.assertEqual(self.rules.read_text(), "original rules")

    def test_changes_remain_pending_on_every_check_until_manual_acceptance(self):
        monitor.check(self.root, self.fetch)
        monitor.accept(self.root)
        self.assertEqual(monitor.check(self.root, self.fetch), 0)
        changed = dict(self.original, text=self.original["text"] + "\nNew seal rule")
        fetch = lambda url: changed if url.endswith("rotation-cooldowns-pve-dps") else self.original.copy()
        for _ in range(2):
            self.assertEqual(monitor.check(self.root, fetch), 2)
            self.assertEqual(self.state()["pending"], 1)
            self.assertIn("New seal rule", (self.root / ".guide-monitor/report.md").read_text())
        self.assertEqual(self.rules.read_text(), "original rules")
        monitor.accept(self.root, "1.60.2")
        self.assertEqual(monitor.check(self.root, fetch), 0)
        self.assertIn('patch = "1.60.2"', (self.root / "MyPalladin/GuideInfo.lua").read_text())
        self.assertEqual(len(list((self.root / ".guide-monitor/history").glob("*.md"))), 5)

    def test_failed_fetch_preserves_snapshots_and_blocks_acceptance(self):
        monitor.check(self.root, self.fetch)
        monitor.accept(self.root)
        saved = self.state()["latest"]

        def fail(url):
            raise OSError("Network unavailable")

        self.assertEqual(monitor.check(self.root, fail), 1)
        self.assertEqual(self.state()["latest"], saved)
        self.assertEqual(len(self.state()["errors"]), 8)
        self.assertFalse(self.state()["complete"])
        with self.assertRaises(ValueError):
            monitor.accept(self.root)
        self.assertIn("Network unavailable", (self.root / ".guide-monitor/report.md").read_text())

    def test_date_only_change_and_unmonitored_subpage_are_reported(self):
        monitor.check(self.root, self.fetch)
        monitor.accept(self.root)
        linked = monitor.BASE + "level-30-dps-overview"
        changed = dict(self.original, modified="2026-11-15", links=[linked])
        self.assertEqual(monitor.check(self.root, lambda url: changed.copy()), 2)
        report = (self.root / ".guide-monitor/report.md").read_text()
        self.assertIn("2026-11-15", report)
        self.assertIn(linked, report)

    def test_acceptance_requires_complete_capture_and_valid_patch(self):
        with self.assertRaises(ValueError):
            monitor.accept(self.root)
        monitor.check(self.root, self.fetch)
        with self.assertRaises(ValueError):
            monitor.accept(self.root, '1.60.1"; injected=true')
        self.assertEqual(self.state()["reviewed"], {})

    def test_old_markup_snapshots_are_normalized_on_both_sides(self):
        monitor.check(self.root, self.fetch)
        state = self.state()
        old = dict(self.original, text='[nav]Old menu[/nav][h2]Content[/h2]\n[cta href="guide=34796"]Camping[/cta]')
        state["latest"] = {page["slug"]: old.copy() for page in self.config["pages"]}
        state["reviewed"] = {page["slug"]: old.copy() for page in self.config["pages"]}
        monitor.write_json(self.root / ".guide-monitor/state.json", state)
        upgraded = monitor.load_state(self.root / ".guide-monitor")
        self.assertEqual(upgraded["reviewed"], upgraded["latest"])
        article = next(iter(upgraded["latest"].values()))
        self.assertNotIn("Old menu", article["text"])
        self.assertIn("Content", article["text"])
        self.assertEqual(article["links"], ["https://www.wowhead.com/forever/guide=34796"])


class NotificationTests(unittest.TestCase):
    @patch.object(monitor.subprocess, "run")
    @patch.object(monitor.shutil, "which", return_value="/usr/bin/notify-send")
    def test_only_pending_or_failed_checks_notify(self, which, run):
        monitor.notify_result(0, ROOT)
        run.assert_not_called()
        monitor.notify_result(2, ROOT)
        self.assertIn("guias aguardam revisão", run.call_args.args[0][2])
        monitor.notify_result(1, ROOT)
        self.assertIn("erro na consulta", run.call_args.args[0][2])

    @patch.object(monitor.subprocess, "run", side_effect=OSError("No desktop bus"))
    @patch.object(monitor.shutil, "which", return_value="/usr/bin/notify-send")
    def test_notification_failure_does_not_break_monitor(self, which, run):
        monitor.notify_result(2, ROOT)


if __name__ == "__main__":
    unittest.main()
