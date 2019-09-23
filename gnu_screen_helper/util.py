#!/usr/bin/env python3

from pathlib import Path


def make_directories(path: Path, mode: int) -> None:
    for parent in reversed(path.parents):
        if parent.is_dir():
            continue
        parent.mkdir(mode=mode)

    if path.is_dir():
        return
    path.mkdir(mode=mode)
