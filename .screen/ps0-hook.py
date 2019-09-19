#!/usr/bin/env python3

import re
import os.path
from argparse import (ArgumentParser,)
import shlex
from typing import (Optional, List)
from sys import (stderr, exit)
import inspect


def abort(message: str) -> None:
    frame = inspect.currentframe()
    if frame is None:
        print(f'\x1b[91mERROR: {message}\x1b[m', file=stderr)
        exit(1)

    frame = frame.f_back
    if frame is None:
        print('\x1b[91mERROR: Could not get the next outer frame'
              ' object.\x1b[m', file=stderr)
        exit(1)

    code = frame.f_code
    if code is None:
        print('\x1b[91mERROR: Could not get the code object from a frame'
              ' object.\x1b[m', file=stderr)
        exit(1)

    filename = code.co_filename
    if filename is None:
        print('\x1b[91mERROR: Could not get the file name from a code'
              ' object.\x1b[m', file=stderr)
        exit(1)

    line_number = frame.f_lineno
    if line_number is None:
        print('\x1b[91mERROR: Could not get the line number from a frame'
              ' object.\x1b[m', file=stderr)
        exit(1)

    print(f'\x1b[91m{filename}:{line_number}: {message}\x1b[m', file=stderr)
    exit(1)


class Command(object):
    def __init__(self, command: str):
        words = shlex.split(command)

        variable_assignment_pattern = re.compile('^[0-9A-Z_a-z]+=(.*)$')
        i = 0
        while i < len(words):
            m = re.search(variable_assignment_pattern, words[i])
            if m is None:
                break
            i += 1

        self._variable_assignments = words[:i]
        self._words = words[i:]

    @staticmethod
    def create_with_words(words: List[str]) -> 'Command':
        return Command(' '.join(words))

    def __repr__(self) -> str:
        s = ' '.join(self._variable_assignments)
        t = ' '.join(self._words)
        if s != '' and t != '':
            return f'{s} {t}'
        return s + t

    @property
    def num_words(self) -> int:
        return len(self._words)

    @property
    def words(self) -> List[str]:
        return self._words

    @property
    def first_word(self) -> Optional[str]:
        if len(self._words) == 0:
            return None

        return self._words[0]


class History(object):
    def __init__(self, history: str, history_line_header_pattern):
        self._commands = []
        for i, line in enumerate(history.splitlines()):
            line_number = i + 1
            line = re.sub(history_line_header_pattern, '', line)
            if line == '':
                raise RuntimeError('An empty line in the history.')
            command = Command(line)
            self._commands.append(command)

    @property
    def is_empty(self) -> bool:
        return len(self._commands) == 0

    @property
    def last_command(self) -> Optional[Command]:
        if len(self._commands) == 0:
            return None
        return self._commands[-1]


class Job(object):
    def __init__(self, jobs_line: str):
        jobs_line_pattern = re.compile(
            '^\\[(\\d+)\\]([+-])?\\s+(Running|Stopped|Done)?\\s+(.*)$')
        m = re.search(jobs_line_pattern, jobs_line)
        if m is None:
            raise RuntimeError(f"An invalid line in `jobs' output: {line}")
        self._number = int(m.group(1))
        self._is_current = (m.group(2) == '+')
        self._is_previous = (m.group(2) == '-')
        self._state = m.group(3).lower()
        self._command = Command(m.group(4))

    @property
    def number(self) -> int:
        return self._number

    @property
    def is_current(self) -> bool:
        return self._is_current

    @property
    def is_previous(self) -> bool:
        return self._is_previous

    @property
    def state(self) -> str:
        return self._state

    @property
    def command(self) -> Command:
        return self._command


class JobTable(object):
    def __init__(self, jobs: str):
        self._jobs = []
        for i, jobs_line in enumerate(jobs.splitlines()):
            line_number = i + 1
            if jobs_line == '':
                raise RuntimeError("An empty line in the `jobs' output.")
            job = Job(jobs_line)
            self._jobs.append(job)

    def find(self, job_spec: str) -> Optional[Job]:
        if job_spec in ('%%', '%+', '%'):
            for job in self._jobs:
                if job.is_current:
                    return job
            return None

        if job_spec == '%-':
            for job in self._jobs:
                if job.is_previous:
                    return job
            for job in self._jobs:
                if job.is_current:
                    return job
            return None

        m = re.search('^%?(\\d+)$', job_spec)
        if m is not None:
            job_number = int(m.group(1))
            for job in self._jobs:
                if job.number == job_number:
                    return job
            return None

        m = re.search('^%?\\?(.*)$', job_spec)
        if m is not None:
            query = m.group(1)
            for job in self._jobs:
                command = job.command
                if str(command).find(query) != -1:
                    return job
            return None

        m = re.search('^%?(.*)$', job_spec)
        if m is not None:
            query = m.group(1)
            for job in self._jobs:
                command = job.command
                if str(command).find(query) == 0:
                    return job
            return None

        return None


class Parameters(object):
    def __init__(self):
        parser = ArgumentParser(
            description="This script is supposed to be executed from an"
            " interactive shell running on an window of a GNU `screen'"
            " session. The script sets the window title to a short"
            " description of the job that is about to be executed by a"
            " command line and the window hardstatus to a detailed"
            " description. It is done by printing the escape sequences"
            " `<ESC>k<window title><ESC>\' and"
            " `<ESC>_<window hardstatus><ESC>\' to the standard output."
            " In order for the script to be executed automatically"
            " immediately after entering a command line, it should be"
            " associated with `DEBUG' trap or `PS0' environment"
            " variable.")
        parser.add_argument('HISTORY', help="Must be `$(history 1)'.")
        parser.add_argument('JOBS', help="Must be `$(jobs)'.")
        parser.add_argument('--history-line-header', metavar='PATTERN',
                            help="A Python regular expression that matches the"
                            " header of each line in `HISTORY'.")
        parser.add_argument(
            '--wrapping-command', action='append', default=[],
            metavar='COMMAND', help="A command that is supposed as a"
            " `wrapping' command. This option can be specified multiple times."
            " A wrapping command is one that executes a part of its arguments"
            " as a command line. For example, `time' is a good candidate as a"
            " wrapping command. If a command line starts with one of specified"
            " commands as wrapping commands, the name of not the wrapping"
            " command but the wrapped command is used as a short description"
            " printed to the window title.")
        params = parser.parse_args()

        history_line_header_pattern\
            = re.compile(f'^{params.history_line_header}')

        self._wrapping_commands = set(params.wrapping_command)

        self._history = History(params.HISTORY, history_line_header_pattern)

        self._job_table = JobTable(params.JOBS)

    @property
    def history(self) -> History:
        return self._history

    @property
    def job_table(self) -> JobTable:
        return self._job_table

    @property
    def wrapping_commands(self) -> List[str]:
        return self._wrapping_commands


def strip_wrapping_commands(params: Parameters, words: List[str]) -> Command:
    if len(words) == 0:
        return Command('')

    wrapping_commands = params.wrapping_commands
    if words[0] not in wrapping_commands\
       and os.path.basename(words[0]) not in wrapping_commands:
        return Command.create_with_words(words)

    for i in range(1, len(words)):
        if words[i] in ('-', '--'):
            return strip_wrapping_commands(params, words[i + 1:])
        if not words[i].startswith('-'):
            return strip_wrapping_commands(params, words[i:])

    return Command('')


def get_foreground_command(params: Parameters) -> Optional[Command]:
    history = params.history
    if history.is_empty:
        return None

    last_command = history.last_command
    assert(last_command is not None)

    if last_command.num_words >= 1 and last_command.first_word == 'fg':
        if last_command.num_words == 1:
            job_spec = '%+'
        else:
            assert(last_command.num_words >= 2)
            job_spec = last_command.words[1]

        job_table = params.job_table
        job = job_table.find(job_spec)
        if job is None:
            return None

        return job.command

    return last_command


def update_window_title(params: Parameters) -> None:
    foreground_command = get_foreground_command(params)
    if foreground_command is None:
        return

    stripped_foreground_command = strip_wrapping_commands(
        params, foreground_command.words)
    if stripped_foreground_command.num_words == 0:
        return

    window_title = os.path.basename(stripped_foreground_command.words[0])
    print(f'\x1bk{window_title}\x1b\\', end='')


def update_window_hardstatus(params: Parameters) -> None:
    foreground_command = get_foreground_command(params)
    if foreground_command is None:
        return

    window_hardstatus = str(foreground_command)
    print(f'\x1b_{window_hardstatus}\x1b\\', end='')


if __name__ == '__main__':
    try:
        params = Parameters()
        update_window_title(params)
        update_window_hardstatus(params)
        exit(0)
    except Exception as e:
        abort(str(e))
