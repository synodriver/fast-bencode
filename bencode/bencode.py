from typing import Tuple, List
from bencode.BTL import BTFailure


def decode_int(x: str, f: int) -> Tuple[int, int]:
    """
    i开头 e结束 i123e
    :param x:
    :param f:
    :return:
    """
    # assert x[f] == "i"
    f += 1
    end = x.index('e', f)
    number = int(x[f:end])
    if x[f] == '-':
        if x[f + 1] == '0':
            raise ValueError
    elif x[f] == '0' and end != f + 1:  # 不能加多余的0
        raise ValueError
    return (number, end + 1)


def decode_string(x: str, f: int) -> Tuple[str, int]:
    """
    :param x: 3:abc
    :param f: 偏移
    :return: 解析出来的字符串和下一个偏移
    """
    colon = x.index(':', f)  # ：的索引
    length = int(x[f:colon])  # 长度
    if x[f] == '0' and colon != f + 1:
        raise ValueError
    colon += 1
    return (x[colon:colon + length], colon + length)


def decode_list(x: str, f: int) -> Tuple[list, int]:
    """
    l3:abci123ee
    :param x:
    :param f:
    :return:
    """
    # assert x[f] == "l"
    ret, f = [], f + 1
    while x[f] != 'e':
        v, f = decode_func[x[f]](x, f)
        ret.append(v)
    return (ret, f + 1)


def decode_dict(x: str, f: int) -> Tuple[dict, int]:
    """

    :param x:
    :param f: 偏移量
    :return:
    """
    r, f = {}, f + 1
    while x[f] != 'e':  # dict 以e结束
        k, f = decode_string(x, f)
        r[k], f = decode_func[x[f]](x, f)
    return (r, f + 1)


decode_func = {}
decode_func['l'] = decode_list
decode_func['d'] = decode_dict  # type: ignore
decode_func['i'] = decode_int  # type: ignore
decode_func['0'] = decode_string  # type: ignore
decode_func['1'] = decode_string  # type: ignore
decode_func['2'] = decode_string  # type: ignore
decode_func['3'] = decode_string  # type: ignore
decode_func['4'] = decode_string  # type: ignore
decode_func['5'] = decode_string  # type: ignore
decode_func['6'] = decode_string  # type: ignore
decode_func['7'] = decode_string  # type: ignore
decode_func['8'] = decode_string  # type: ignore
decode_func['9'] = decode_string  # type: ignore


def bdecode(x: str):
    try:
        r, l = decode_func[x[0]](x, 0)
    except (IndexError, KeyError, ValueError):
        raise BTFailure("not a valid bencoded string")
    if l != len(x):
        raise BTFailure("invalid bencoded value (data after valid prefix)")
    return r


class Bencached(object):
    __slots__ = ['bencoded']

    def __init__(self, s):
        self.bencoded = s


def encode_bencached(x: Bencached, r: List[str]):
    r.append(x.bencoded)


def encode_int(x: int, r: List[str]):
    r.extend(('i', str(x), 'e'))


def encode_bool(x, r):
    if x:
        encode_int(1, r)
    else:
        encode_int(0, r)


def encode_string(x: str, r: List[str]):
    r.extend((str(len(x)), ':', x))


def encode_list(x: list, r: List[str]):
    r.append('l')
    for i in x:
        encode_func[type(i)](i, r)
    r.append('e')


def encode_dict(x: dict, ret: List[str]):
    ret.append('d')
    ilist = list(x.items())
    ilist.sort()
    for k, v in ilist:
        ret.extend((str(len(k)), ':', k))
        encode_func[type(v)](v, ret)
    ret.append('e')


encode_func = {}
encode_func[Bencached] = encode_bencached
encode_func[int] = encode_int  # type: ignore
encode_func[str] = encode_string  # type: ignore
encode_func[list] = encode_list  # type: ignore
encode_func[tuple] = encode_list  # type: ignore
encode_func[dict] = encode_dict  # type: ignore
encode_func[bool] = encode_bool  # type: ignore


def bencode(x) -> str:
    r = []
    encode_func[type(x)](x, r)
    return ''.join(r)


try:
    from ._bencode import bencode, bdecode, BTFailure  # type: ignore
except ImportError:
    pass

