# -*- coding: utf-8 -*-
import sys
import unittest

sys.path.append(".")

from bencode import dumps, loads

data = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe".encode()


class Test(unittest.TestCase):
    def test_decode(self):
        self.assertEqual(
            loads(data),
            {"a": {"id": "abcdefghij0123456789"}, "q": "ping", "t": "aa", "y": "q"},
        )

    def test_encode(self):
        self.assertEqual(
            dumps(
                {"a": {"id": "abcdefghij0123456789"}, "q": "ping", "t": "aa", "y": "q"}
            ),
            data,
        )

    def test_file(self):
        with open("./[桜都字幕组]2021年03月合集.torrent.loaded", "rb") as f:
            data = f.read()
        ret = loads(data)
        encoded = dumps(ret)
        self.assertEqual(encoded, data)


if __name__ == "__main__":
    unittest.main()
