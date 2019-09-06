#!/usr/bin/env python3

import re
import math
from pathlib import (Path,)
import os
from argparse import ArgumentParser
import getpass
import subprocess
from subprocess import (PIPE,)
import socket
from typing import (Tuple,)
from sys import (exit,)
import inspect


def abort(message: str) -> None:
    frame = inspect.currentframe()
    if frame is None:
        print(f'  \x05{{+ kr}}ERROR: {message}\x05{{-}}')
        exit(1)

    frame = frame.f_back
    if frame is None:
        print('  \x05{+ kr}ERROR: Could not get the next outer frame\
 object.\x05{-}')
        exit(1)

    code = frame.f_code
    if code is None:
        print('  \x05{+ kr}ERROR: Could not get the code object from a frame\
 object.\x05{-}')
        exit(1)

    filename = code.co_filename
    if filename is None:
        print('  \x05{+ kr}ERROR: Could not get the file name from a code\
 object.\x05{-}')
        exit(1)

    line_number = frame.f_lineno
    if line_number is None:
        print('  \x05{+ kr}ERROR: Could not get the line number from a code\
 object.\x05{-}')
        exit(1)

    print(f'  \x05{{= kr}}{filename}:{line_number}: {message}\x05{{-}}')
    exit(1)


class Parameters(object):
    def __init__(self):
        parser = ArgumentParser()
        parser.add_argument('STY')
        parser.add_argument('--left-padding', type=int, default=50,
                            metavar='INTEGER')
        parser.add_argument('--fqdn', action='store_true')
        parser.add_argument('--bar-max-length', type=int, default=20,
                            metavar='INTEGER')
        parser.add_argument('--cpu-yellow', type=float, default=0.5,
                            metavar='FLOAT')
        parser.add_argument('--cpu-red', type=float, default=0.8,
                            metavar='FLOAT')
        parser.add_argument('--memory-yellow', type=float, default=0.5,
                            metavar='FLOAT')
        parser.add_argument('--memory-red', type=float, default=0.8,
                            metavar='FLOAT')

        params = parser.parse_args()

        m = re.search('^(?:\\d+\\.)?pts-(\\d+)\\.', params.STY)
        if m is None:
            abort(f"ERROR: {params.STY}: Failed to parse `STY'.")
        self._tty_device_path = Path(f'/dev/pts/' + m.group(1))
        if not self._tty_device_path.exists():
            abort(f"ERROR: {self._tty_device_path}: tty device does not\
 exist.")

        if params.left_padding <= 0:
            abort(f"ERROR: {params.LEFT_PADDING}: An invalid value for\
 `--left-padding'.")
        self._left_padding = params.left_padding

        self._requires_fqdn = params.fqdn

        if params.bar_max_length <= 0:
            abort(f"ERROR: {params.bar_max_length}: An invalid value for\
 `--bar-max-length'.")
        self._bar_max_length = params.bar_max_length

        if params.cpu_yellow < 0.0:
            abort(f"ERROR: {params.cpu_yellow}: An invalid value for\
 `--cpu-yellow'.")
        self._cpu_yellow_threshold = params.cpu_yellow

        if params.cpu_red < self._cpu_yellow_threshold:
            abort("ERROR: `--cpu-red' is less than `--cpu-yellow'.")
        self._cpu_red_threshold = params.cpu_red

        if params.memory_yellow < 0.0:
            abort(f"ERROR: {params.memory_yellow}: An invalid value for\
 `--memory-yellow'.")
        self._memory_yellow_threshold = params.memory_yellow

        if params.memory_red < self._memory_yellow_threshold:
            abort(f"ERROR: `--memory-red' is less than `--memory-yellow'.")
        self._memory_red_threshold = params.memory_red

    @property
    def tty_device_path(self) -> Path:
        return self._tty_device_path

    @property
    def left_padding(self) -> int:
        return self._left_padding

    @property
    def requires_fqdn(self) -> bool:
        return self._requires_fqdn

    @property
    def bar_max_length(self) -> int:
        return self._bar_max_length

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


def get_cpu_usage_text() -> Tuple[float, float, str]:
    cpu_count = float(os.cpu_count())
    load_avg_1min, load_avg_5min, load_avg_15min = os.getloadavg()
    cpu_count_oom = int(math.log(cpu_count + 0.5, 10.0)) + 1
    cpu_usage_text_format = f'{{0:{cpu_count_oom + 3}.2F}}\
 / {{1:{cpu_count_oom + 3}.2F}}'
    cpu_usage_text = cpu_usage_text_format.format(load_avg_1min, cpu_count)
    return (cpu_count, load_avg_1min, cpu_usage_text)


def get_memory_usage_text() -> Tuple[float, float, str]:
    total_memory = None
    avail_memory = None
    with open('/proc/meminfo') as meminfo_file:
        for line in meminfo_file:
            if line.startswith('MemTotal:'):
                m = re.search('(\\d+) kB$', line)
                if m is None:
                    abort("Failed to parse `/proc/meminfo'.")
                total_memory = int(m.group(1))
                if avail_memory is not None:
                    break
                continue

            if line.startswith('MemAvailable:'):
                m = re.search('(\\d+) kB$', line)
                if m is None:
                    abort("Failed to parse `/proc/meminfo'.")
                avail_memory = int(m.group(1))
                if total_memory is not None:
                    break
                continue

    if total_memory is None:
        abort("Failed to extract `MemTotal' from `/proc/meminfo'.")
    if avail_memory is None:
        abort("Failed to extract `MemAvailable' from `/proc/meminfo'.")

    total_memory = total_memory / 1024
    avail_memory = avail_memory / 1024
    memory_usage = total_memory - avail_memory

    total_memory_oom = int(math.log(total_memory + 0.5, 10.0)) + 1
    memory_usage_text_format = f'{{0:>{total_memory_oom}.0F}}MiB\
 / {{1:>{total_memory_oom}.0F}}MiB'
    memory_usage_text = memory_usage_text_format.format(memory_usage,
                                                        total_memory)
    return (total_memory, memory_usage, memory_usage_text)


def get_ratio_bar(total: float, value: float, max_length: int) -> str:
    length = int(min(max_length * value / total, max_length))
    return '*' * length + ' ' * (max_length - length)


def get_right_text(params: Parameters,
                   available_columns: int) -> Tuple[str, int]:
    username = getpass.getuser()
    username_text = None
    if params.requires_fqdn:
        hostname = socket.getfqdn()
        username_text = f'{username}@{hostname}'
    if username_text is None or len(username_text) + 2 > available_columns:
        hostname = socket.gethostname()
        username_text = f'{username}@{hostname}'
        if len(username_text) + 2 > available_columns:
            username_text = username
            if len(username_text) + 2 > available_columns:
                return ('', params.left_padding + available_columns)
    available_columns -= len(username_text) + 2

    cpu_count, cpu_load, cpu_usage_text = get_cpu_usage_text()
    total_memory, memory_usage, memory_usage_text = get_memory_usage_text()
    if len(cpu_usage_text) + len(memory_usage_text) + 8 > available_columns:
        return (f'  {username_text}', params.left_padding + available_columns)
    available_columns -= len(cpu_usage_text) + len(memory_usage_text) + 8

    if available_columns < 22:
        return (
            f'  [{cpu_usage_text}]  [{memory_usage_text}]  {username_text}',
            params.left_padding + available_columns)

    bar_max_length = min((available_columns - 2) // 2, params.bar_max_length)

    cpu_usage_bar_text = get_ratio_bar(cpu_count, cpu_load, bar_max_length)
    if cpu_load / cpu_count >= params.cpu_red_threshold:
        cpu_usage_bar_text = f'\x05{{+ Rk}}{cpu_usage_bar_text}\x05{{-}}'
    elif cpu_load / cpu_count >= params.cpu_yellow_threshold:
        cpu_usage_bar_text = f'\x05{{+ Yk}}{cpu_usage_bar_text}\x05{{-}}'
    else:
        cpu_usage_bar_text = f'\x05{{+ Bk}}{cpu_usage_bar_text}\x05{{-}}'

    memory_usage_bar_text = get_ratio_bar(total_memory, memory_usage,
                                          bar_max_length)
    if memory_usage / total_memory >= params.memory_red_threshold:
        memory_usage_bar_text\
            = f'\x05{{+ Rk}}{memory_usage_bar_text}\x05{{-}}'
    elif memory_usage / total_memory >= params.memory_yellow_threshold:
        memory_usage_bar_text\
            = f'\x05{{+ Yk}}{memory_usage_bar_text}\x05{{-}}'
    else:
        memory_usage_bar_text\
            = f'\x05{{+ Bk}}{memory_usage_bar_text}\x05{{-}}'

    available_columns -= (bar_max_length + 1) * 2
    right_text = f'  [{cpu_usage_text} {cpu_usage_bar_text}]'\
        + f'  [{memory_usage_text} {memory_usage_bar_text}]'\
        + f'  {username_text}'
    return (right_text, params.left_padding + available_columns)


def get_left_text(available_columns: int) -> str:
    return f'\x0502=\x05-w\x05{{+u wk}}\x05n \x0550L>\x05t\x05{{-}}\x05+w\
\x050{available_columns}='


def main(params: Parameters) -> None:
    process = subprocess.run(
        ['stty', '-F', str(params.tty_device_path), 'size'],
        stdout=PIPE, stderr=PIPE, encoding='UTF-8')
    if process.returncode != 0:
        abort("ERROR: Failed to execute `stty'.")

    lines, columns = process.stdout.rstrip().split(' ')
    lines = int(lines)
    columns = int(columns) - 8
    right_text, available_columns = get_right_text(
        params, columns - params.left_padding)
    left_text = get_left_text(available_columns)
    print(left_text + right_text)


if __name__ == '__main__':
    try:
        params = Parameters()
        main(params)
    except Exception as e:
        abort(f'ERROR: Terminated abnormally due to an exception.: {e}')
    exit(0)
