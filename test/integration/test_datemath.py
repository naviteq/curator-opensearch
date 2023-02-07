import opensearchpy
import curator
import os
import json
import string, random, tempfile
import click
from click import testing as clicktest
from mock import patch, Mock
from datetime import timedelta, datetime, date

from . import CuratorTestCase
from . import testvars as testvars

import logging

logger = logging.getLogger(__name__)

host, port = os.environ.get("TEST_ES_SERVER", "localhost:9200").split(":")
port = int(port) if port else 9200


class TestParseDateMath(CuratorTestCase):
    def test_function_positive(self):
        test_string = "<.prefix-{2001-01-01-13||+1h/h{yyyy-MM-dd-HH|-07:00}}-suffix>"
        expected = ".prefix-2001-01-01-14-suffix"
        self.assertEqual(expected, curator.parse_datemath(self.client, test_string))

    def test_assorted_datemaths(self):
        for test_string, expected in [
            (
                "<prefix-{now}-suffix>",
                "prefix-{0}-suffix".format(datetime.utcnow().strftime("%Y.%m.%d")),
            ),
            (
                "<prefix-{now-1d/d}>",
                "prefix-{0}".format(
                    (datetime.utcnow() - timedelta(days=1)).strftime("%Y.%m.%d")
                ),
            ),
            (
                "<{now+1d/d}>",
                "{0}".format(
                    (datetime.utcnow() + timedelta(days=1)).strftime("%Y.%m.%d")
                ),
            ),
            (
                "<{now+1d/d}>",
                "{0}".format(
                    (datetime.utcnow() + timedelta(days=1)).strftime("%Y.%m.%d")
                ),
            ),
            (
                "<{now+10d/d{yyyy-MM}}>",
                "{0}".format(
                    (datetime.utcnow() + timedelta(days=10)).strftime("%Y-%m")
                ),
            ),
            (
                "<{now+10d/h{yyyy-MM-dd-HH|-07:00}}>",
                "{0}".format(
                    (
                        datetime.utcnow() + timedelta(days=10) - timedelta(hours=7)
                    ).strftime("%Y-%m-%d-%H")
                ),
            ),
        ]:
            self.assertEqual(expected, curator.parse_datemath(self.client, test_string))
