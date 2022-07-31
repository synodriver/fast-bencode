# -*- coding: utf-8 -*-
try:
    from bencode._bencode import BTFailure, bdecode, bencode
except ImportError:
    from bencode.bencode import BTFailure, bdecode, bencode

__all__ = ["bencode", "bdecode"]
