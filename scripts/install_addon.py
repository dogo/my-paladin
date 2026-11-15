#!/usr/bin/env python3
"""Install MyPaladin with backups and migrate the old MyPalladin settings. Close WoW first."""
import argparse
from datetime import datetime
from pathlib import Path
import re
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GAME = Path.home() / "Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_"


def running_game():
    for path in Path("/proc").glob("[0-9]*/comm"):
        try:
            if path.read_text().strip().lower() in {"wow.exe", "wowclassic.exe", "wow", "wow-64.exe"}:
                return True
        except OSError:
            continue
    return False


def install(game, source=ROOT / "MyPaladin"):
    game, source = Path(game), Path(source)
    if running_game():
        raise RuntimeError("Close World of Warcraft before installing; SavedVariables may be overwritten by the game.")
    if not (game / "WTF").is_dir() or not (game / "Interface/AddOns").is_dir():
        raise ValueError("Expected _forever_/WTF and _forever_/Interface/AddOns")
    toc = source / "MyPaladin.toc"
    files = [toc] + [source / line.strip() for line in toc.read_text().splitlines()
                     if line.strip() and not line.startswith("#")]
    for file in files:
        if file.parent != source or not file.is_file():
            raise ValueError(f"Invalid addon manifest entry: {file.name}")
    migrations = []
    for old in (game / "WTF").glob("**/SavedVariables/MyPalladin.lua"):
        target = old.with_name("MyPaladin.lua")
        if target.exists():
            continue  # New settings win on a repeated installation.
        content, changed = re.subn(r"(?m)^MyPalladinDB\s*=", "MyPaladinDB =", old.read_text(), count=1)
        if changed != 1:
            raise ValueError(f"Missing MyPalladinDB assignment in {old}; original preserved")
        migrations.append((old, target, content))
    backup_root = game / "Interface/MyPaladin-backups"
    backup_root.mkdir(exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix=datetime.now().strftime("%Y%m%d-%H%M%S-"), dir=backup_root))
    addons = game / "Interface/AddOns"
    with tempfile.TemporaryDirectory(prefix="MyPaladin-install-", dir=game / "Interface") as temporary:
        staged = Path(temporary) / "MyPaladin"
        staged.mkdir()
        for file in files:
            shutil.copy2(file, staged / file.name)
        for old, target, content in migrations:
            relative = old.relative_to(game)
            copy = backup / relative
            copy.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(old, copy)
            with tempfile.NamedTemporaryFile(mode="w", dir=target.parent, delete=False) as handle:
                handle.write(content)
                handle.flush()
                temp_path = Path(handle.name)
            try:
                temp_path.replace(target)
            finally:
                temp_path.unlink(missing_ok=True)
        moved = []
        try:
            for name in ("MyPalladin", "MyPaladin"):
                current = addons / name
                if current.exists():
                    current.rename(backup / name)
                    moved.append(name)
            staged.rename(addons / "MyPaladin")
        except OSError:
            for name in reversed(moved):
                (backup / name).rename(addons / name)
            raise
    return backup, len(migrations)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-dir", type=Path, default=DEFAULT_GAME)
    args = parser.parse_args()
    try:
        backup, count = install(args.game_dir)
    except (OSError, ValueError, RuntimeError) as error:
        parser.exit(1, f"Installation failed: {error}\n")
    print(f"Installed MyPaladin. Migrated characters: {count}. Backup: {backup}")


if __name__ == "__main__":
    main()
