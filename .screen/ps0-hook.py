#!/usr/bin/env python3

import re
import os.path
from argparse import (ArgumentParser,)
import shlex
from typing import (List,)
from sys import (stderr, exit)
import inspect


def print_to_window_title(s: str) -> None:
    print(f'\x1bk{s}\x1b\\', end='')


def print_to_window_hardstatus(s: str) -> None:
    print(f'\x1b_{s}\x1b\\', end='')


def abort(message: str) -> None:
    frame = inspect.currentframe()
    if frame is None:
        print(f'\x1b[91mERROR: {message}\x1b[m', file=stderr)
        exit(1)

    frame = frame.f_back
    if frame is None:
        print('\x1b[91mERROR: Could not get the next outer frame\
 object.\x1b[m', file=stderr)
        exit(1)

    code = frame.f_code
    if code is None:
        print('\x1b[91mERROR: Could not get the code object from a frame\
 object.\x1b[m', file=stderr)
        exit(1)

    filename = code.co_filename
    if filename is None:
        print('\x1b[91mERROR: Could not get the file name from a code\
 object.\x1b[m', file=stderr)
        exit(1)

    line_number = frame.f_lineno
    if line_number is None:
        print('\x1b[91mERROR: Could not get the line number from a code\
 object.\x1b[m', file=stderr)
        exit(1)

    print(f'\x1b[91m{filename}:{line_number}: {message}\x1b[m', file=stderr)
    exit(1)


class Parameters(object):
    def __init__(self):
        parser = ArgumentParser()
        parser.add_argument('HISTORY_LAST_LINE')
        parser.add_argument('--history-line-header')
        parser.add_argument('--ignore-wrapping-command', action='append',
                            default=[])

        params = parser.parse_args()

        if params.HISTORY_LAST_LINE == '':
            abort("ERROR: `HISTORY_LAST_LINE' is empty.")
        history_last_line = params.HISTORY_LAST_LINE

        history_line_header_pattern\
            = re.compile(f'^{params.history_line_header}')

        command = re.sub(history_line_header_pattern, '', history_last_line)
        self._command_words = shlex.split(command)
        if len(self._command_words) == 0:
            abort("ERROR: Failed to parse `HISTORY_LAST_LINE'.")

        self._wrapping_commands = set(params.ignore_wrapping_command)

    def _strip_wrapping_commands(self, words: List[str]) -> List[str]:
        if len(words) == 0:
            return []

        if words[0] not in self._wrapping_commands\
           and os.path.basename(words[0]) not in self._wrapping_commands:
            return words

        for i in range(1, len(words)):
            if words[i] in ('-', '--'):
                return self._strip_wrapping_commands(words[i + 1:])

            if not words[i].startswith('-'):
                return self._strip_wrapping_commands(words[i:])

        return []

    def get_window_title(self) -> str:
        stripped_words = self._strip_wrapping_commands(self._command_words)
        return os.path.basename(stripped_words[0])

    def get_window_hardstatus(self) -> str:
        return ' '.join(self._command_words)


if __name__ == '__main__':
    try:
        params = Parameters()
        print_to_window_title(params.get_window_title())
        print_to_window_hardstatus(params.get_window_hardstatus())
        exit(0)
    except Exception as e:
        abort(str(e))
