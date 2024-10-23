from typing import Any

class BTFailure(Exception):
    pass

def bencode(data: Any, bufsize: int = 100000) -> bytes: ...
def bdecode(data: bytes, decode: bool = True) -> Any: ...
