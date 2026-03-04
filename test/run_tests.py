#!/usr/bin/env python
"""Test runner: forwards to pytest. Supports `python test/run_tests.py unit` for unit tests."""

from __future__ import print_function

import sys
from os.path import dirname, abspath

import pytest


def run_all(argv=None):
    if argv is None:
        argv = sys.argv[:1]
    test_dir = abspath(dirname(__file__))
    # Map "unit" / "integration" to test/unit or test/integration; default to full test dir
    if len(argv) > 1 and argv[1] == "unit":
        pytest_args = [str(test_dir + "/unit"), "-v"]
    elif len(argv) > 1 and argv[1] == "integration":
        pytest_args = [str(test_dir + "/integration"), "-v"]
    else:
        pytest_args = [str(test_dir), "-v"]
    # Add any extra args (e.g. -x, --tb=short) after the first
    if len(argv) > 2:
        pytest_args.extend(argv[2:])
    sys.exit(pytest.main(pytest_args))


if __name__ == "__main__":
    run_all(sys.argv)
