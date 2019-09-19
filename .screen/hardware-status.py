#!/usr/bin/env python3

import re
import math
from pathlib import Path
import os
import time
from argparse import ArgumentParser
import getpass
import subprocess
from subprocess import PIPE, DEVNULL
import socket
from typing import Optional, Tuple, List
from sys import exit
from daemon.pidfile import TimeoutPIDLockFile
from daemon import DaemonContext


class Parameters(object):
    def __init__(self):
        parser = ArgumentParser()
        parser.add_argument('--daemonize', metavar='PID_FILE')
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

        if params.daemonize is not None:
            self._pid_file_path = Path(params.daemonize)
            self._pid_file_path = self._pid_file_path.expanduser()
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


class ScreenSession(object):
    def __init__(self, sty: str):
        m = re.search('^(\\d+)\\.pts-(\\d+)\\.\\S*$', sty)
        if m is not None:
            self._sty = sty
            self._pid = int(m.group(1))
            self._tty_dev_path = Path(f'/dev/pts/{m.group(2)}')
            return

        m = re.search('^(\\d+)\\.(pty\\d+)\\.\\S*$', sty)
        if m is not None:
            # On Cygwin.
            self._sty = sty
            self._pid = int(m.group(1))
            self._tty_dev_path = Path(f'/dev/{m.group(2)}')
            return

        raise ValueError(f"ERROR: {sty}: Invalid value for `sty'.")

    @property
    def sty(self) -> str:
        return self._sty

    @property
    def pid(self) -> int:
        return self._pid

    @property
    def tty_device_path(self) -> Path:
        return self._tty_dev_path


def get_all_screen_sessions() -> List[ScreenSession]:
    process = subprocess.run(
        ['screen', '-ls'], stdin=DEVNULL, stdout=PIPE, stderr=PIPE,
        encoding='UTF-8')

    if process.stdout.startswith('No Sockets found in '):
        return []

    # `screen -ls` of old GNU screens (4.01.00devel on CentOS 7.6.1810
    # at least) exits with a non-zero status even if there exists a
    # session. Therefore, exit status cannot be used to check whether
    # an error occurs.

    if not process.stdout.startswith('There is a screen on:')\
       and not process.stdout.startswith('There are screens on:'):
        raise RuntimeError(f'''ERROR: Failed to execute the following command:
args: {process.args}
stdout: {process.stdout}
stderr: {process.stderr}
returncode: {process.returncode}''')

    screen_sessions = []
    for line in process.stdout.splitlines():
        m = re.search('^\\s*(\\d+\\.pts-\\d+\\.\\S+)'
                      '\\s+.*\\((?:Attached|Detached)\\)$', line)
        if m is not None:
            screen_session = ScreenSession(m.group(1))
            screen_sessions.append(screen_session)
            continue

        m = re.search('^\\s*(\\d+\\.pty\\d+\\.\\S+)'
                      '\\s+.*\\((?:Attached|Detached)\\)$', line)
        if m is not None:
            screen_session = ScreenSession(m.group(1))
            screen_sessions.append(screen_session)
            continue

    return screen_sessions


def get_cpu_usage_text() -> Tuple[float, float, str]:
    cpu_count = float(os.cpu_count())
    load_avg_1min, load_avg_5min, load_avg_15min = os.getloadavg()
    cpu_count_oom = int(math.log(cpu_count + 0.5, 10.0)) + 1
    cpu_usage_text_format = f'{{0:{cpu_count_oom + 3}.2F}}\
 / {{1:{cpu_count_oom + 3}.2F}}'
    cpu_usage_text = cpu_usage_text_format.format(load_avg_1min, cpu_count)
    return (cpu_count, load_avg_1min, cpu_usage_text)


def get_memory_usage_text() -> Tuple[float, float, str]:
    # On Cygwin, `MemAvailable` is not available. Therefore, fall back
    # to `MemFree`.
    total_memory = None
    avail_memory = None
    free_memory = None
    with open('/proc/meminfo') as meminfo_file:
        for line in meminfo_file:
            if line.startswith('MemTotal:'):
                m = re.search('(\\d+) kB$', line)
                if m is None:
                    abort("Failed to parse `/proc/meminfo'.")
                total_memory = int(m.group(1))
                if avail_memory is not None and free_memory is not None:
                    break
                continue

            if line.startswith('MemAvailable:'):
                m = re.search('(\\d+) kB$', line)
                if m is None:
                    abort("Failed to parse `/proc/meminfo'.")
                avail_memory = int(m.group(1))
                if total_memory is not None and free_memory is not None:
                    break
                continue

            if line.startswith('MemFree:'):
                m = re.search('(\\d+) kB$', line)
                if m is None:
                    abort("Failed to parse `/proc/meminfo'.")
                free_memory = int(m.group(1))
                if total_memory is not None and avail_memory is not None:
                    break
                continue

    if total_memory is None:
        abort("Failed to extract `MemTotal' from `/proc/meminfo'.")
    if avail_memory is None and free_memory is None:
        abort("Failed to extract `MemAvailable' and `MemFree' from"
              " `/proc/meminfo'.")

    avail_memory = avail_memory if avail_memory is not None else free_memory

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
    return '#' * length + ' ' * (max_length - length)


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
                return ('', available_columns)
    available_columns -= len(username_text) + 2

    cpu_count, cpu_load, cpu_usage_text = get_cpu_usage_text()
    total_memory, memory_usage, memory_usage_text = get_memory_usage_text()
    if len(cpu_usage_text) + len(memory_usage_text) + 8 > available_columns:
        return (f'  {username_text}', available_columns)
    available_columns -= len(cpu_usage_text) + len(memory_usage_text) + 8

    if (params.bar_min_length + 1) * 2 > available_columns:
        return (
            f'  [{cpu_usage_text}]  [{memory_usage_text}]  {username_text}',
            available_columns)
    bar_max_length = min((available_columns - 2) // 2, params.bar_max_length)

    cpu_usage_bar_text = get_ratio_bar(cpu_count, cpu_load, bar_max_length)
    if cpu_load / cpu_count >= params.cpu_red_threshold:
        cpu_usage_bar_text = f'%{{+ Rk}}{cpu_usage_bar_text}%{{-}}'
    elif cpu_load / cpu_count >= params.cpu_yellow_threshold:
        cpu_usage_bar_text = f'%{{+ Yk}}{cpu_usage_bar_text}%{{-}}'
    else:
        cpu_usage_bar_text = f'%{{+ Gk}}{cpu_usage_bar_text}%{{-}}'

    memory_usage_bar_text = get_ratio_bar(total_memory, memory_usage,
                                          bar_max_length)
    if memory_usage / total_memory >= params.memory_red_threshold:
        memory_usage_bar_text = f'%{{+ Rk}}{memory_usage_bar_text}%{{-}}'
    elif memory_usage / total_memory >= params.memory_yellow_threshold:
        memory_usage_bar_text = f'%{{+ Yk}}{memory_usage_bar_text}%{{-}}'
    else:
        memory_usage_bar_text = f'%{{+ Gk}}{memory_usage_bar_text}%{{-}}'

    available_columns -= (bar_max_length + 1) * 2
    right_text = f'  [{cpu_usage_text} {cpu_usage_bar_text}]'\
        + f'  [{memory_usage_text} {memory_usage_bar_text}]'\
        + f'  {username_text}'
    return (right_text, available_columns)


def get_left_text(padding_for_window_list: int) -> str:
    return '%{= bw}%02c:%02s%{-}%+010=%-w%{+u wk}%n %50L>%t%{-}%+w'\
        f'%+0{padding_for_window_list}='


def update_hardware_status(params: Parameters,
                           screen_session: ScreenSession) -> None:
    tty_device_path = screen_session.tty_device_path
    if not tty_device_path.is_char_device():
        return

    process = subprocess.run(
        ['stty', '-F', str(tty_device_path), 'size'],
        stdin=DEVNULL, stdout=PIPE, stderr=PIPE, encoding='UTF-8')
    if process.returncode != 0:
        return

    lines, columns = process.stdout.rstrip().split(' ')
    lines = int(lines)
    columns = int(columns)
    right_text, remaining_columns = get_right_text(
        params, columns - 10 - params.min_padding_for_window_list)
    left_text = get_left_text(
        params.min_padding_for_window_list + remaining_columns)
    hardware_status_line = f'{left_text}{right_text}'

    process = subprocess.run(
        ['screen', '-S', screen_session.sty,
         '-X', 'hardstatus', 'alwayslastline', hardware_status_line],
        stdin=DEVNULL, stdout=PIPE, stderr=PIPE, encoding='UTF-8')


def main(params: Parameters) -> None:
    while True:
        screen_sessions = get_all_screen_sessions()
        if len(screen_sessions) == 0:
            break
        for screen_session in screen_sessions:
            update_hardware_status(params, screen_session)
        time.sleep(params.interval)


if __name__ == '__main__':
    params = Parameters()
    if params.pid_file_path is not None:
        pid_file_path = params.pid_file_path
        pid_dir_path = pid_file_path.parent
        pid_dir_path.mkdir(mode=0o700, exist_ok=True)
        pid_file = TimeoutPIDLockFile(pid_file_path, acquire_timeout=0.0)
        with DaemonContext(umask=0o022, pidfile=pid_file):
            main(params)
    else:
        main(params)
    exit(0)
