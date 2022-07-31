# cython: language_level=3
from libc.string cimport strchr
from libc.stdint cimport uint8_t, int64_t
from libc.string cimport memcpy

from cpython.long cimport PyLong_Check
from cpython.unicode cimport PyUnicode_Check
from cpython.conversion cimport PyOS_snprintf
from cpython.bytes cimport PyBytes_FromStringAndSize, PyBytes_Check
from cpython.bytearray cimport PyByteArray_Check
from cpython.list cimport PyList_Check
from cpython.tuple cimport PyTuple_Check
from cpython.dict cimport PyDict_Check
from cpython.bool cimport PyBool_Check
from cpython.mem cimport PyMem_Malloc, PyMem_Free

cdef extern from "util.h" nogil:
    int CM_Atoi(char* source, int size, int64_t* integer)


from typing import Tuple, List  # todo del
from io import BytesIO # todo del

class BTFailure(Exception):
    pass

ctypedef fused string:
    str
    bytes

# bytes.index
cdef Py_ssize_t bytes_index(const uint8_t[::1] data, int c, Py_ssize_t offset) nogil:
    cdef char* substring = strchr(<const char *>&data[offset], c)
    return <Py_ssize_t>(substring - &data[0])

cdef Py_ssize_t decode_int(const uint8_t[::1] x, Py_ssize_t *f) except? 0:
    """
    i开头 e结束 i123e
    :param x:
    :param f:
    :return:
    """
    # assert data[offset] == "i"
    f[0] += 1
    # end = data.index(b'e', offset)
    cdef Py_ssize_t end = bytes_index(x, 101, f[0])
    # number = int(data[offset:end])
    cdef int64_t n
    CM_Atoi(<char*>&x[f[0]], <int>(end-f[0]), &n)  # fixme use custom one
    if x[f[0]] == 45:  # '-'
        if x[f[0] + 1] == 48:  # ord('0')  # can not be negative
            raise ValueError
    elif x[f[0]] == 48 and end != f[0] + 1:  # 不能加多余的0
        raise ValueError
    f[0] = end + 1
    return <Py_ssize_t>n


cdef object decode_string(const uint8_t[::1] data , Py_ssize_t* offset):  # todo fused types
    """
    :param data: 3:abc
    :param offset: 偏移
    :return: 解析出来的字符串和下一个偏移
    """
    # colon = data.index(b':', offset)  # ：的索引
    # print(f"offset {offset[0]}") # todo del
    cdef Py_ssize_t colon = bytes_index(data, 58, offset[0])
    # print(f"colon: {colon}")
    cdef int64_t length
    # cdef Py_ssize_t length = int(data[offset:colon])  # 长度 fixme use custom one
    CM_Atoi(<char*>&data[offset[0]], <int>(colon-offset[0]), &length)
    if data[offset[0]] == 48 and colon != offset[0] + 1:
        raise ValueError
    colon += 1
    offset[0] = colon + <Py_ssize_t>length
    cdef bytes tmp = PyBytes_FromStringAndSize(<char*>&data[colon], length)
    try:
        # return (<bytes>data[colon:colon + length]).decode()
        return tmp.decode()
    except UnicodeDecodeError:
        return tmp

cdef list decode_list(const uint8_t[::1] data,  Py_ssize_t* offset):
    """
    l3:abci123ee
    :param data:
    :param offset: current offset pointer, will be updated to the next chunk 
    :return:
    """
    # assert data[offset] == "l"
    # ret, offset = [], offset + 1
    offset[0] += 1
    cdef:
        list ret = []
        uint8_t tmp
    tmp = data[offset[0]]
    while tmp != 101:
        # v, offset = decode_func[data[offset[0]]](data, offset)
        if tmp == 108:
            v = decode_list(data, offset)
        elif tmp == 100:
            v = decode_dict(data, offset)
        elif tmp ==105:
            v = decode_int(data, offset)
        elif 48 <=tmp <=57:
            v = decode_string(data ,offset)
        else:
            raise ValueError
        tmp = data[offset[0]]
        ret.append(v)
    offset[0] += 1
    return ret


cdef dict decode_dict(const uint8_t[::1] data ,  Py_ssize_t* offset):
    """

    :param data:
    :param offset: 偏移量
    :return:
    """
    cdef:
        dict ret = {}
        uint8_t tmp
    offset[0]+=1
    # print(f"in decode_dict offset: {offset[0]}")  # todo del
    tmp = data[offset[0]]
    while tmp != 101:  # dict 以e结束  ord(e)
        key =  decode_string(data, offset)
        # print(f"dict got key {key}") # todo del
        # print(f"now  offset is {offset[0]}")
        tmp = data[offset[0]]
        if tmp == 108:
            v = decode_list(data, offset)
        elif tmp == 100:
            v = decode_dict(data, offset)
        elif tmp ==105:
            v = decode_int(data, offset)
        elif 48 <=tmp <=57:
            v = decode_string(data ,offset)
        else:
            raise ValueError
        tmp = data[offset[0]]
        ret[key] = v
    offset[0] += 1
    return ret


# decode_func = {}
# decode_func[ord('l')] = decode_list
# decode_func[ord('d')] = decode_dict  # type: ignore
# decode_func[ord('i')] = decode_int  # type: ignore
# decode_func[ord('0')] = decode_string  # type: ignore
# decode_func[ord('1')] = decode_string  # type: ignore
# decode_func[ord('2')] = decode_string  # type: ignore
# decode_func[ord('3')] = decode_string  # type: ignore
# decode_func[ord('4')] = decode_string  # type: ignore
# decode_func[ord('5')] = decode_string  # type: ignore
# decode_func[ord('6')] = decode_string  # type: ignore
# decode_func[ord('7')] = decode_string  # type: ignore
# decode_func[ord('8')] = decode_string  # type: ignore
# decode_func[ord('9')] = decode_string  # type: ignore


cpdef object bdecode(const uint8_t[::1] data):
    """
    bdecode(data: bytes) -> Any

    """
    cdef:
        Py_ssize_t offset = 0
        uint8_t tmp
    tmp = data[0]
    try:
        if tmp == 108:
            v = decode_list(data, &offset)
        elif tmp == 100:
            v = decode_dict(data, &offset)
        elif tmp == 105:
            v = decode_int(data, &offset)
        elif 48 <= tmp <= 57:
            v = decode_string(data, &offset)
        else:
            raise ValueError
    except (IndexError, KeyError, ValueError):
        raise BTFailure("not a valid bencoded string")
    if offset != data.shape[0]:
        raise BTFailure("invalid bencoded value (data after valid prefix)")
    return v


cdef class Bencached:
    cdef public bytes bencoded

    def __cinit__(self, bytes s):
        self.bencoded = s  # type: bytes


def encode_bencached(Bencached data, object r):
    r.write(data.bencoded)


cdef encode_int(int data, object r):
    cdef char buf[20]
    cdef int count = PyOS_snprintf(buf, 20,"i%de", data)
    r.write(<bytes>buf[:count])


cdef encode_bool(bint data, object r):
    if data:
        encode_int(1, r)
    else:
        encode_int(0, r)


cdef int encode_string(str data, object r) except? -1:
    # cdef:
    #     bytes d = data.encode()
    #     Py_ssize_t size = PyBytes_GET_SIZE(d)
    #     char* buf = <char*>PyMem_Malloc(<size_t>size + 30)
    #     int count
    # if not buf:
    #     raise MemoryError
    # try:
    #     count = PyOS_snprintf(buf, <size_t>size + 30, "%d:%s", size, <char*>d)
    #     r.write(<bytes>buf[:count-1])
    # finally:
    #     PyMem_Free(buf)
    return encode_bytes(data.encode(), r)

cdef int encode_bytes(const uint8_t[::1] data, object r) except? -1:
    cdef:
        Py_ssize_t size = data.shape[0]
        char * buf = <char *> PyMem_Malloc(<size_t> size + 30)
        int count
    if not buf:
        raise MemoryError
    try:
        count = PyOS_snprintf(buf, <size_t>size + 30, "%d:", size)
        # print(f"in encode_bytes, count = {count}")
        memcpy(&buf[count], &data[0], <size_t>size)
        r.write(<bytes>buf[:count+<int>size])
    finally:
        PyMem_Free(buf)
    # r.write(b''.join((str(len(data)).encode(), b':', data)))


cdef int encode_list(list data, object r) except? -1:
    r.write(b'l')
    for i in data:
        # encode_func[type(i)](i, r)
        tp = type(i)
        if tp == Bencached:
            encode_bencached(i, r)
        elif PyLong_Check(i):
            encode_int(i, r)
        elif PyUnicode_Check(i):
            encode_string(i, r)
        elif PyBytes_Check(i) or PyByteArray_Check(i):
            encode_bytes(i, r)
        elif PyList_Check(i) or PyTuple_Check(i):
            encode_list(i ,r)
        elif PyDict_Check(i):
            encode_dict(i ,r)
        elif PyBool_Check(i):
            encode_bool(i, r)
    r.write(b'e')


cdef int encode_dict(dict data, object  ret) except? -1:
    ret.write(b'd')
    cdef list ilist = list(data.items()) # todo should we sort?
    ilist.sort()
    for key, v in ilist:
        # ret.write(b''.join((str(len(k)).encode(), b':', k.encode() if isinstance(k, str) else k)))
        if PyUnicode_Check(key):
            encode_string(key ,ret)
        else:
            encode_bytes(key, ret)
        tp = type(v)
        if tp == Bencached:
            encode_bencached(v, ret)
        elif PyLong_Check(v):
            encode_int(v, ret)
        elif PyUnicode_Check(v):
            encode_string(v, ret)
        elif PyBytes_Check(v) or PyByteArray_Check(v):
            encode_bytes(v, ret)
        elif PyList_Check(v) or PyTuple_Check(v):
            encode_list(v, ret)
        elif PyDict_Check(v):
            encode_dict(v, ret)
        elif PyBool_Check(v):
            encode_bool(v, ret)
    ret.write(b'e')


# encode_func = {}
# encode_func[Bencached] = encode_bencached
# encode_func[int] = encode_int  # type: ignore
# encode_func[str] = encode_string  # type: ignore
# encode_func[bytes] = encode_bytes  # type: ignore
# encode_func[list] = encode_list  # type: ignore
# encode_func[tuple] = encode_list  # type: ignore
# encode_func[dict] = encode_dict  # type: ignore
# encode_func[bool] = encode_bool  # type: ignore


cpdef bytes bencode(object data):
    """
    bencode(data) -> bytes

    """
    ret = BytesIO()  # todo bytearray
    tp = type(data)
    if tp == Bencached:
        encode_bencached(data, ret)
    elif PyLong_Check(data):
        encode_int(data, ret)
    elif PyUnicode_Check(data):
        encode_string(data, ret)
    elif PyBytes_Check(data) or PyByteArray_Check(data):
        encode_bytes(data, ret)
    elif PyList_Check(data) or PyTuple_Check(data):
        encode_list(data, ret)
    elif PyDict_Check(data):
        encode_dict(data, ret)
    elif PyBool_Check(data):
        encode_bool(data, ret)
    return ret.getvalue()
