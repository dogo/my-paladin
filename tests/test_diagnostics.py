import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / f"scripts/{name}.py")
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


monitor = module("monitor_session")
installer = module("install_addon")


def event(seq=1, state="echo_swap", count=2):
    return {"schema": 1, "session": "123456-1", "seq": seq, "feature": "seal_hud", "state": state, "count": count}


def line(record):
    return monitor.PREFIX + json.dumps(record)


class DiagnosticsTests(unittest.TestCase):
    def test_reads_native_and_lua_strings_without_executing_code(self):
        record = event()
        self.assertEqual(list(monitor.records("[timestamp] " + line(record))), [record])
        saved = "[1] = " + json.dumps(line(record)) + ", os.execute('never execute')"
        self.assertEqual(list(monitor.records(saved, saved=True)), [record])
        self.assertEqual(list(monitor.records("MPALADIN1|{broken")), [])
        self.assertEqual(list(monitor.records(line({**record, "count": float("nan")}))), [])
        self.assertEqual(list(monitor.records(line({**record, "schema": 2}))), [])
        self.assertEqual(list(monitor.records(line({**record, "session": []}))), [])
        with_extra = list(monitor.records(line({**record, "guid": "do not export"})))[0]
        self.assertNotIn("guid", with_extra)

    def test_tail_partial_lines_dedupe_saved_reload_and_rotation(self):
        with tempfile.TemporaryDirectory() as directory:
            game = Path(directory)
            logs = game / "Logs"
            logs.mkdir()
            saved = game / "WTF/Account/test/SavedVariables/MyPaladin.lua"
            saved.parent.mkdir(parents=True)
            native = logs / "DeveloperLog.log"
            tail = monitor.Monitor(game)
            content = line(event()) + "\n"
            native.write_text(content[:20])
            self.assertEqual(tail.poll(), [])
            with native.open("a") as handle:
                handle.write(content[20:])
            self.assertEqual(tail.poll(), [event()])
            saved.write_text("MyPaladinLog = {\n[1] = " + json.dumps(line(event())) + ",\n}\n")
            self.assertEqual(tail.poll(), [])
            native.rename(logs / "rotated.txt")
            native.write_text(line(event(2, "echo_return", 0)) + "\n")
            self.assertEqual(tail.poll(), [event(2, "echo_return", 0)])
            saved.write_text("[1] = " + json.dumps(line(event(3, "echo_build", 1))) + ",")
            self.assertEqual(tail.poll(), [event(3, "echo_build", 1)])
            tail.write_report(game / "output")
            report = (game / "output/report.md").read_text()
            self.assertTrue(tail.live_seen)
            self.assertIn("Inconsistências na contagem de ecos: 0", report)
            self.assertIn("error: não observado", report)
            native.write_text(line(event(4, "echo_swap", 0)) + "\n")
            tail.poll()
            self.assertIn("Inconsistências na contagem de ecos: 1", tail.report()[0])


class InstallationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.game = Path(temporary.name)
        self.old = self.game / "Interface/AddOns/MyPalladin"
        self.old.mkdir(parents=True)
        (self.old / "MyPalladin.toc").write_text("old version")
        self.saved = self.game / "WTF/Account/test/SavedVariables/MyPalladin.lua"
        self.saved.parent.mkdir(parents=True)
        self.original = 'MyPalladinDB = { ["activeProfile"] = "raid", ["compact"] = false }\n'
        self.saved.write_text(self.original)
        check = patch.object(installer, "running_game", return_value=False)
        check.start()
        self.addCleanup(check.stop)

    def test_migration_backup_new_filenames_and_idempotence(self):
        backup, count = installer.install(self.game)
        target = self.saved.with_name("MyPaladin.lua")
        self.assertEqual(count, 1)
        self.assertEqual(self.saved.read_text(), self.original)
        self.assertEqual(target.read_text(), self.original.replace("MyPalladinDB", "MyPaladinDB"))
        self.assertEqual((backup / self.saved.relative_to(self.game)).read_text(), self.original)
        self.assertFalse(self.old.exists())
        installed = self.game / "Interface/AddOns/MyPaladin"
        self.assertTrue((installed / "MyPaladin.toc").is_file())
        self.assertTrue((installed / "Diagnostics.lua").is_file())
        target.write_text("new settings win")
        _, count = installer.install(self.game)
        self.assertEqual(count, 0)
        self.assertEqual(target.read_text(), "new settings win")

    def test_malformed_settings_and_open_game_preserve_old_install(self):
        self.saved.write_text("unexpected format")
        with self.assertRaises(ValueError):
            installer.install(self.game)
        self.assertTrue(self.old.exists())
        self.assertFalse(self.saved.with_name("MyPaladin.lua").exists())
        with patch.object(installer, "running_game", return_value=True), self.assertRaises(RuntimeError):
            installer.install(self.game)
        self.assertTrue(self.old.exists())

    def test_swap_failure_restores_installed_addon(self):
        rename = Path.rename

        def fail_staged(path, destination):
            if path.parent.name.startswith("MyPaladin-install-"):
                raise OSError("simulated write failure")
            return rename(path, destination)

        with patch.object(Path, "rename", fail_staged), self.assertRaises(OSError):
            installer.install(self.game)
        self.assertEqual((self.old / "MyPalladin.toc").read_text(), "old version")


if __name__ == "__main__":
    unittest.main()
