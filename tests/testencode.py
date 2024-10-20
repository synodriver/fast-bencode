# -*- coding: utf-8 -*-
import sys
import unittest

sys.path.append(".")

from bencode import dumps, loads, BTFailure

data = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe".encode()


class Test(unittest.TestCase):
    def test_decode(self):
        self.assertEqual(
            loads(data),
            {"a": {"id": "abcdefghij0123456789"}, "q": "ping", "t": "aa", "y": "q"},
        )
        self.assertEqual(loads(b"li1ei2ei3e4:3141e"), [1, 2, 3, "3141"])

    def test_encode(self):
        self.assertEqual(
            dumps(
                {"a": {"id": "abcdefghij0123456789"}, "q": "ping", "t": "aa", "y": "q"}
            ),
            data,
        )

    def test_decode_big_int(self):
        self.assertEqual(dumps(2147483647), b'i2147483647e')
        self.assertEqual(dumps(2147483648), b'i2147483648e')
        self.assertEqual(dumps(11856280181), b'i11856280181e')

    def test_decode_neg(self):
        self.assertEqual(loads(b"i-42e"), -42)

    def test_raise(self):
        with self.assertRaises(BTFailure):
            data = bytearray(b"i4200e")
            loads(data[:2])

    # def test_file(self):
    #     with open("./[桜都字幕组]2021年03月合集.torrent.loaded", "rb") as f:
    #         data = f.read()
    #     ret = loads(data)
    #     encoded = dumps(ret)
    #     self.assertEqual(encoded, data)


if __name__ == "__main__":
    unittest.main()
