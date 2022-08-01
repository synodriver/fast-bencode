# -*- coding: utf-8 -*-
try:
    from bencode._bencode import BTFailure, bdecode, bencode
except ImportError:
    from bencode.bencode import BTFailure, bdecode, bencode

loads = bdecode
dumps = bencode


__all__ = ["bdecode", "bencode", "loads", "dumps"]
