#!/usr/bin/env python3
"""
dots - Script for maintaining a dotfiles repo.

Subcommands:
    add   Save a given file into the dotfiles repo and replace it with a symlink.
    sync  Read the manifest file and (re)create symlinks for all tracked dotfiles.

This is a Python port of the original JBang/Java implementation. No third-party
dependencies are required (json/argparse/pathlib are all in the standard library).
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

HOME_PATH = Path.home()
MANIFEST_PATH = HOME_PATH / "dotfiles" / "manifest.json"


def read_manifest() -> list:
    if not MANIFEST_PATH.exists():
        return []
    raw = MANIFEST_PATH.read_text()
    if not raw.strip():
        return []
    return json.loads(raw)


def write_manifest(entries: list) -> None:
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(entries, indent=2))


def cmd_add(args) -> int:
    file_path = Path(args.file).resolve()

    try:
        target_rel = file_path.relative_to(HOME_PATH)
    except ValueError:
        print(f"cannot add {file_path.name}: file is not under home directory ({HOME_PATH})")
        return 1

    source_path = HOME_PATH / "dotfiles" / target_rel
    target_path = file_path

    print(f"Source = {source_path} | Target = {target_path}")

    if source_path.exists():
        print(f"cannot add {file_path.name}: file already in dotfiles repo")
        return 1

    if not file_path.is_file() or file_path.is_symlink():
        print(f"cannot add {file_path.name}: file is not a regular file")
        return 1

    try:
        source_path.parent.mkdir(parents=True, exist_ok=True)

        # move the target file to the source (dotfiles repo)
        shutil.move(str(target_path), str(source_path))

        # create a symlink at the original location pointing to the repo copy
        target_path.symlink_to(source_path)

        entries = read_manifest()
        entries.append({
            "source": str(source_path),
            "target": str(target_rel),
        })
        write_manifest(entries)

        print(f"\n\nsuccessfully saved {target_rel.name}. "
              f"A symlink has been created in {target_path.parent}")
        return 0

    except FileExistsError as e:
        print(f"File already exists: {e.filename}")
        return 1
    except FileNotFoundError as e:
        print(f"No such file: {e.filename}")
        return 1
    except Exception as e:
        print(str(e))
        return 1


def cmd_sync(args) -> int:
    try:
        entries = read_manifest()
    except Exception as e:
        print(str(e))
        return 1

    errors = 0
    for entry in entries:
        source_path = Path(entry["source"])
        target_rel = entry["target"]
        target_path = HOME_PATH / target_rel

        print(target_path)

        if not source_path.exists():
            print(f"File not found: {source_path}")
            errors += 1
            continue

        if target_path.exists() and not target_path.is_symlink():
            # back up the existing target file before replacing it
            backup_path = Path(str(target_path) + ".bak")
            target_path.rename(backup_path)
            print(f"deleted and created: {target_rel}")
            target_path.symlink_to(source_path)
            continue

        if target_path.is_symlink() or not target_path.exists():
            # remove a stale symlink if present, then (re)create it
            if target_path.is_symlink():
                target_path.unlink()
            target_path.symlink_to(source_path)

    return 1 if errors else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dots",
        description="Script for maintaining dotsfile",
    )
    parser.add_argument("--version", action="version", version="dots 0.1")
    subparsers = parser.add_subparsers(dest="command")

    add_parser = subparsers.add_parser(
        "add", description="Save a given file to the dotfiles repo"
    )
    add_parser.add_argument("file", help="Path to the file to save in the dotfiles repo")
    add_parser.set_defaults(func=cmd_add)

    sync_parser = subparsers.add_parser(
        "sync", description="Reads the manifest file and creates symlinks"
    )
    sync_parser.set_defaults(func=cmd_sync)

    return parser


def main(argv=None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if not hasattr(args, "func"):
        parser.print_help()
        return 0

    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
