"""
Copyright (c) 2008-2022 synodriver <synodriver@gmail.com>
"""
import time

from bencode._bencode import bdecode as c_bdecode
from bencode._bencode import bencode as c_bencode
from bencode.bencode import bdecode, bencode

with open("./[桜都字幕组]2021年03月合集.torrent.loaded", "rb") as f:
    data = f.read()
start = time.time()
for i in range(1000):
    decoded = bdecode(data)
    re = bencode(decoded)


print(f"pure python spend {time.time() - start}")

start = time.time()
for i in range(1000):
    decoded = c_bdecode(data)
    re = c_bencode(decoded)


print(f"cython spend {time.time() - start}")
