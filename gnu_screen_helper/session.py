#!/usr/bin/env python3

import re
from pathlib import Path
import os
from typing import List
from gnu_screen_helper.parameters import Parameters


class ScreenSession(object):
    def __init__(self, params: Parameters, sty: str):
        m = re.search('^(\\d+)\\.pts-\\d+\\.\\S+$', sty)
        if m is not None:
            self._sty = sty
            self._pid = int(m.group(1))
            self._runtime_data_dir_path\
                = params.runtime_data_prefix / 'session' / self._sty
            return

        m = re.search('^(\\d+)\\.pty\\d+\\.\\S+$', sty)
        if m is not None:
            self._sty = sty
            self._pid = int(m.group(1))
            self._runtime_data_dir_path\
                = params.runtime_data_prefix / 'session' / self._sty
            return

        raise RuntimeError(f"ERROR: {sty}: Invalid value for `sty'.")


    @property
    def sty(self) -> str:
        return self._sty

    @property
    def pid(self) -> int:
        return self._pid

    @property
    def runtime_data_dir_path(self) -> Path:
        return self._runtime_data_dir_path

    def get_outer_terminal_file_paths(self) -> List[Path]:
        outer_terminal_file_paths = []
        for open_file_path in Path(f'/proc/{self._pid}/fd').glob('*'):
            if open_file_path.is_symlink():
                open_file_path = Path(os.readlink(open_file_path))

            m = re.search('^/dev/pts/\\d+$', str(open_file_path))
            if m is not None:
                outer_terminal_file_paths.append(open_file_path)
                continue

            m = re.search('^/dev/pty\\d+$', str(open_file_path))
            if m is not None:
                outer_terminal_file_paths.append(open_file_path)
                continue

        return outer_terminal_file_paths


def get_all_sessions(params: Parameters,
                     socket_dir: Path) -> List[ScreenSession]:
    sessions = []
    for socket_path in socket_dir.glob('*'):
        sty = socket_path.name

        m = re.search('^\\d+\\.pts-\\d+\\..*$', sty)
        if m is not None:
            if not socket_path.is_fifo() and not socket_path.is_socket():
                continue
            session = ScreenSession(params, sty)
            sessions.append(session)
            continue

        m = re.search('^\\d+\\.pty\\d+\\..*$', sty)
        if m is not None:
            if not socket_path.is_fifo() and not socket_path.is_socket():
                continue
            session = ScreenSession(params, sty)
            sessions.append(session)
            continue

    return sessions
