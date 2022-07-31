# -*- coding: utf-8 -*-
try:
    from bencode._bencode import bencode, bdecode, BTFailure
except ImportError:
    from bencode.bencode import bencode, bdecode, BTFailure

__all__ = ["bencode", "bdecode"]
