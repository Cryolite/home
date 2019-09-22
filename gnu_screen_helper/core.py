#!/usr/bin/env python3

import re
from pathlib import Path
from subprocess import DEVNULL, PIPE
import subprocess


def get_screen_socket_dir() -> Path:
    process = subprocess.run(['screen', '-ls'], stdin=DEVNULL, stdout=PIPE,
                             stderr=PIPE, encoding='UTF-8')
    m = re.search('^(?:No Sockets found|1 Socket|\\d+ Sockets) in (.*)\\.$',
                  process.stdout.rstrip(), re.MULTILINE)
    if m is None:
        raise RuntimeError(f"""ERROR: Failed to parse output of `screen -ls'.
args: {process.args}
stdout: {process.stdout}
stderr: {process.stderr}
returncode: {process.returncode}""")

    socket_dir = Path(m.group(1))
    if not socket_dir.is_dir():
        raise RuntimeError(f"""ERROR: Failed to parse output of `screen -ls'.
args: {process.args}
stdout: {process.stdout}
stderr: {process.stderr}
returncode: {process.returncode}""")

    return socket_dir
