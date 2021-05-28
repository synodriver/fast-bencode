# -*- coding: utf-8 -*-
import unittest
import sys

sys.path.append("../")

from bencode import bdecode, bencode

data = "d1:ad2:id20:abcdefghij0123456789e1:q4:ping1:t2:aa1:y1:qe"


class Test(unittest.TestCase):
    def test_decode(self):
        self.assertEqual(bdecode(data), {'a': {'id': 'abcdefghij0123456789'}, 'q': 'ping', 't': 'aa', 'y': 'q'})

    def test_encode(self):
        self.assertEqual(bencode({'a': {'id': 'abcdefghij0123456789'}, 'q': 'ping', 't': 'aa', 'y': 'q'}), data)


if __name__ == "__main__":
    unittest.main()
