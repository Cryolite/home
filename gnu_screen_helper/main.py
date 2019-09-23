#!/usr/bin/env python3

import re
import math
import shutil
import os
import time
import getpass
from subprocess import PIPE, DEVNULL
import subprocess
import socket
from typing import Tuple, List
from sys import exit
from daemon.pidfile import TimeoutPIDLockFile
from daemon import DaemonContext
from gnu_screen_helper.util import make_directories
from gnu_screen_helper.parameters import Parameters
from gnu_screen_helper.core import get_screen_socket_dir
from gnu_screen_helper.session import (ScreenSession, get_all_sessions)


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


def update_hardware_status(params: Parameters, session: ScreenSession) -> None:
    outer_terminal_file_paths = session.get_outer_terminal_file_paths()

    if len(outer_terminal_file_paths) != 1:
        return
    outer_terminal_file_path = outer_terminal_file_paths[0]

    with open(outer_terminal_file_path) as outer_terminal_file:
        columns, lines = os.get_terminal_size(outer_terminal_file.fileno())

    right_text, remaining_columns = get_right_text(
        params, columns - 10 - params.min_padding_for_window_list)
    left_text = get_left_text(
        params.min_padding_for_window_list + remaining_columns)
    hardware_status_line = f'{left_text}{right_text}'

    process = subprocess.run(
        ['screen', '-S', session.sty,
         '-X', 'hardstatus', 'alwayslastline', hardware_status_line],
        stdin=DEVNULL, stdout=PIPE, stderr=PIPE, encoding='UTF-8')


def cleanup_stale_session_runtime_data(
        params: Parameters, sessions: List[ScreenSession]) -> None:
    session_data_prefix = params.runtime_data_prefix / 'session'
    sty_set = set([s.sty for s in sessions])
    for session_data_dir_path in session_data_prefix.glob('*'):
        if not session_data_dir_path.is_dir():
            continue

        basename = session_data_dir_path.name

        m0 = re.search('^\\d+\\.pts-\\d+\\.\\S+$', basename)
        m1 = re.search('^\\d+\\.pty\\d+\\.\\S+$', basename)
        if m0 is None and m1 is None:
            continue

        if basename in sty_set:
            continue

        shutil.rmtree(session_data_dir_path)


def main_loop(params: Parameters) -> None:
    socket_dir = get_screen_socket_dir()
    while True:
        sessions = get_all_sessions(params, socket_dir)
        cleanup_stale_session_runtime_data(params, sessions)
        if len(sessions) == 0:
            break
        for session in sessions:
            update_hardware_status(params, session)
        time.sleep(params.interval)


def main() -> None:
    params = Parameters()
    if params.pid_file_path is not None:
        pid_file_path = params.pid_file_path
        pid_dir_path = pid_file_path.parent
        make_directories(pid_dir_path, mode=0o700)
        pid_file = TimeoutPIDLockFile(pid_file_path, acquire_timeout=0.0)
        with DaemonContext(umask=0o077, pidfile=pid_file):
            main_loop(params)
    else:
        main_loop(params)
    exit(0)
