#!/usr/bin/env python3

from pathlib import Path
import os
from argparse import ArgumentParser
from typing import Optional


class Parameters(object):
    def __init__(self):
        parser = ArgumentParser()
        parser.add_argument('--runtime-data-prefix', type=Path,
                            metavar='DIRECTORY')
        parser.add_argument('--daemonize', action='store_true')
        parser.add_argument('--interval', type=float, default=1.0,
                            metavar='FLOAT')
        parser.add_argument('--min-padding-for-window-list', type=int,
                            default=50, metavar='INTEGER')
        parser.add_argument('--cpu-yellow', type=float, default=0.5,
                            metavar='FLOAT')
        parser.add_argument('--cpu-red', type=float, default=0.8,
                            metavar='FLOAT')
        parser.add_argument('--memory-yellow', type=float, default=0.5,
                            metavar='FLOAT')
        parser.add_argument('--memory-red', type=float, default=0.8,
                            metavar='FLOAT')
        parser.add_argument('--bar-min-length', type=int, default=10,
                            metavar='INTEGER')
        parser.add_argument('--bar-max-length', type=int, default=20,
                            metavar='INTEGER')
        parser.add_argument('--fqdn', action='store_true')
        params = parser.parse_args()

        if params.runtime_data_prefix is None:
            uid = os.getuid()
            if Path('/run').is_dir():
                self._runtime_data_prefix = Path(f'/run/user/{uid}/screen')
            elif Path('/var/run').is_dir():
                self._runtime_data_prefix = Path(f'/var/run/user/{uid}/screen')
            else:
                raise RuntimeError(
                    "ERROR: Neither `/run' nor `/var/run' available.")

        if params.daemonize:
            self._pid_file_path\
                = self._runtime_data_prefix / 'run' / 'gnu_screen_helper.pid'
        else:
            self._pid_file_path = None

        if params.interval < 0.0:
            raise RuntimeError(
                f"ERROR: {params.interval}: Invalid value for `--interval'.")
        self._interval = params.interval

        if params.min_padding_for_window_list <= 0:
            raise RuntimeError(
                f'ERROR: {params.min_padding_for_window_list}:'
                " Invalid value for `--min-padding-for-window-list'.")
        self._min_padding_for_window_list = params.min_padding_for_window_list

        if params.cpu_yellow < 0.0:
            raise RuntimeError(f'ERROR: {params.cpu_yellow}:'
                               " Invalid value for `--cpu-yellow'.")
        self._cpu_yellow_threshold = params.cpu_yellow

        if params.cpu_red < self._cpu_yellow_threshold:
            raise RuntimeError(
                "ERROR: `--cpu-red' is less than `--cpu-yellow'.")
        self._cpu_red_threshold = params.cpu_red

        if params.memory_yellow < 0.0:
            raise RuntimeError(f'ERROR: {params.memory_yellow}:'
                               " Invalid value for `--memory-yellow'.")
        self._memory_yellow_threshold = params.memory_yellow

        if params.memory_red < self._memory_yellow_threshold:
            raise RuntimeError(
                f"ERROR: `--memory-red' is less than `--memory-yellow'.")
        self._memory_red_threshold = params.memory_red

        if params.bar_min_length <= 0:
            raise RuntimeError(f'ERROR: {params.bar_min_length}:'
                               " Invalid value for `--bar-min-length'.")
        self._bar_min_length = params.bar_min_length

        if params.bar_max_length < self._bar_min_length:
            raise RuntimeError(
                "ERROR: `--bar-max-length' is less than `--bar-min-length'.")
        self._bar_max_length = params.bar_max_length

        self._requires_fqdn = params.fqdn

    @property
    def runtime_data_prefix(self) -> Path:
        return self._runtime_data_prefix

    @property
    def pid_file_path(self) -> Optional[Path]:
        return self._pid_file_path

    @property
    def interval(self) -> float:
        return self._interval

    @property
    def min_padding_for_window_list(self) -> int:
        return self._min_padding_for_window_list

    @property
    def cpu_yellow_threshold(self) -> float:
        return self._cpu_yellow_threshold

    @property
    def cpu_red_threshold(self) -> float:
        return self._cpu_red_threshold

    @property
    def memory_yellow_threshold(self) -> float:
        return self._memory_yellow_threshold

    @property
    def memory_red_threshold(self) -> float:
        return self._memory_red_threshold

    @property
    def bar_min_length(self) -> int:
        return self._bar_min_length

    @property
    def bar_max_length(self) -> int:
        return self._bar_max_length

    @property
    def requires_fqdn(self) -> bool:
        return self._requires_fqdn
