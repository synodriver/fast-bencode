# -*- coding: utf-8 -*-
from typing import IO

try:
    from bencode._bencode import BTFailure, bdecode, bencode  # type: ignore
except ImportError:
    from bencode.bencode import BTFailure, bdecode, bencode

loads = bdecode
dumps = bencode


def load(fp: IO[bytes], decode: bool = True):
    return bdecode(fp.read(), decode)


def dump(obj, fp: IO[bytes], bufsize=100000):
    fp.write(bencode(obj, bufsize))


__all__ = ["bdecode", "bencode", "loads", "dumps", "load", "dump"]
