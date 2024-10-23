# cython: language_level=3
from cpython.bool cimport PyBool_Check
from cpython.bytearray cimport PyByteArray_Check
from cpython.bytes cimport (PyBytes_Check, PyBytes_FromStringAndSize,
                            PyBytes_GET_SIZE)
from cpython.conversion cimport PyOS_snprintf
from cpython.dict cimport PyDict_Check
from cpython.list cimport PyList_Check
from cpython.long cimport PyLong_Check
from cpython.tuple cimport PyTuple_Check
from cpython.unicode cimport (PyUnicode_AsUTF8AndSize, PyUnicode_Check,
                              PyUnicode_FromStringAndSize)
from libc.stdint cimport int64_t, uint8_t
from libc.string cimport memcpy, strchr


cdef extern from "util.h" nogil:
    int CM_Atoi(char* source, int size, int64_t* integer)

cdef extern from "sds.h" nogil:
    ctypedef char * sds
    sds sdsnewlen(void *init, size_t initlen)
    sds sdsnew(char *init)
    sds sdsempty()
    sds sdsdup( sds s)
    size_t sdslen( sds s)
    size_t sdsavail( sds s)
    void sdssetlen(sds s, size_t newlen)
    void sdsinclen(sds s, size_t inc)
    size_t sdsalloc( sds s)
    void sdssetalloc(sds s, size_t newlen)
    void sdsfree(sds s)
    sds sdsgrowzero(sds s, size_t len)
    sds sdscatlen(sds s,  void *t, size_t len)
    sds sdscat(sds s,  char *t)
    sds sdscatsds(sds s,  sds t)
    sds sdscpylen(sds s,  char *t, size_t len)
    sds sdscpy(sds s,  char *t)
    sds sdscatfmt(sds s, char *fmt, ...)
    sds sdstrim(sds s,  char *cset)
    void sdsrange(sds s, ssize_t start, ssize_t end);
    void sdsupdatelen(sds s)
    void sdsclear(sds s)
    int sdscmp( sds s1,  sds s2)
    sds *sdssplitlen( char *s, ssize_t len,  char *sep, int seplen, int *count)
    void sdsfreesplitres(sds *tokens, int count)
    void sdstolower(sds s)
    void sdstoupper(sds s)
    sds sdsfromlonglong(long long value)
    sds sdscatrepr(sds s,  char *p, size_t len_)
    sds *sdssplitargs( char *line, int *argc)
    sds sdsmapchars(sds s, char *from_,  char *to, size_t setlen)
    sds sdsjoin(char **argv, int argc, char *sep)
    sds sdsjoinsds(sds *argv, int argc,  char *sep, size_t seplen)


    sds sdsMakeRoomFor(sds s, size_t addlen)
    void sdsIncrLen(sds s, int incr)
    sds sdsRemoveFreeSpace(sds s)
    size_t sdsAllocSize(sds s)
    void *sdsAllocPtr(sds s)

    
class BTFailure(Exception):
    pass

ctypedef fused string:
    str
    bytes

# bytes.index
cdef Py_ssize_t bytes_index(const uint8_t[::1] data, int c, Py_ssize_t offset) nogil:
    cdef char* substring = strchr(<const char *>&data[offset], c)
    return <Py_ssize_t>(substring - <char*>&data[0])

cdef Py_ssize_t decode_int(const uint8_t[::1] data, Py_ssize_t *offset) except? 0:
    """
    i开头 e结束 i123e
    :param data:
    :param f:
    :return:
    """
    # assert data[offset] == "i"
    offset[0] += 1
    # end = data.index(b'e', offset)
    cdef Py_ssize_t end = bytes_index(data, 101, offset[0])
    if end >= data.shape[0]:
        raise ValueError
    # number = int(data[offset:end])
    cdef int64_t n
    CM_Atoi(<char*>&data[offset[0]], <int>(end-offset[0]), &n)  # fixme use custom one
    if data[offset[0]] == 45:  # '-'
        if data[offset[0] + 1] == 48:  # ord('0')  # can not be negative -0
            raise ValueError
    elif data[offset[0]] == 48 and end != offset[0] + 1:  # 不能加多余的0 e.g. 00
        raise ValueError
    offset[0] = end + 1
    return <Py_ssize_t>n


cdef object decode_string(const uint8_t[::1] data , Py_ssize_t* offset, bint decode):  # todo fused types
    """
    :param data: 3:abc
    :param offset: 偏移
    :return: 解析出来的字符串和下一个偏移
    """
    # colon = data.index(b':', offset)  # ：的索引
    # print(f"offset {offset[0]}") # todo del
    cdef Py_ssize_t colon = bytes_index(data, 58, offset[0])
    if colon >= data.shape[0]:
        raise ValueError
    # print(f"colon: {colon}")
    cdef int64_t length
    # cdef Py_ssize_t length = int(data[offset:colon])  # 长度 fixme use custom one
    CM_Atoi(<char*>&data[offset[0]], <int>(colon-offset[0]), &length)
    if data[offset[0]] == 48 and colon != offset[0] + 1:
        raise ValueError
    colon += 1
    offset[0] = colon + <Py_ssize_t>length
    # cdef bytes tmp = PyBytes_FromStringAndSize(<char*>&data[colon], length) # PyUnicode_FromStringAndSize
    if decode:
        try:
            # return (<bytes>data[colon:colon + length]).decode()
            # return tmp.decode()
            return PyUnicode_FromStringAndSize(<char*>&data[colon], length)
        except UnicodeDecodeError:
            return PyBytes_FromStringAndSize(<char*>&data[colon], length)
    else:
        return PyBytes_FromStringAndSize(<char*>&data[colon], length)

cdef list decode_list(const uint8_t[::1] data, Py_ssize_t* offset, bint decode):
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
        v = decode_any(data, offset, decode)
        tmp = data[offset[0]]
        ret.append(v)
    offset[0] += 1
    return ret


cdef dict decode_dict(const uint8_t[::1] data, Py_ssize_t* offset, bint decode):
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
        key = decode_string(data, offset, decode)
        # print(f"dict got key {key}") # todo del
        # print(f"now  offset is {offset[0]}")
        tmp = data[offset[0]]
        v = decode_any(data, offset, decode)
        tmp = data[offset[0]]
        ret[key] = v
    offset[0] += 1
    return ret

cdef object decode_any(const uint8_t[::1] data, Py_ssize_t* offset, bint decode):
    cdef uint8_t tmp = data[offset[0]]
    cdef object v
    if tmp == 108:
        v = decode_list(data, offset, decode)
    elif tmp == 100:
        v = decode_dict(data, offset, decode)
    elif tmp == 105:
        v = decode_int(data, offset)
    elif 48 <= tmp <=57:
        v = decode_string(data, offset, decode)
    else:
        raise ValueError
    return v


cpdef object bdecode(const uint8_t[::1] data, bint decode = 1):
    """bdecode(data: bytes, decode: bool = True) -> Any

    """
    cdef:
        Py_ssize_t offset = 0
    try:
        v = decode_any(data, &offset, decode)
    except (IndexError, KeyError, ValueError):
        raise BTFailure("not a valid bencoded string")
    if offset != data.shape[0]:
        raise BTFailure("invalid bencoded value (data after valid prefix)")
    return v


cdef class Bencached:
    cdef public bytes bencoded

    def __cinit__(self, bytes s):
        self.bencoded = s  # type: bytes


cdef int encode_bencached(Bencached data, sds* r) except -1:
    cdef Py_ssize_t data_size = PyBytes_GET_SIZE(data.bencoded)
    cdef sds newsds = sdsMakeRoomFor(r[0], <size_t>data_size)
    if newsds == NULL:
        raise MemoryError
    r[0] = newsds
    memcpy(newsds+sdslen(newsds), <char*>data.bencoded, <size_t>data_size)
    sdsIncrLen(newsds, <int>data_size)


cdef int encode_int(int64_t data, sds* r) except -1:
    # cdef char buf[20]
    cdef sds newsds = sdsMakeRoomFor(r[0], 20)
    if newsds == NULL:
        raise MemoryError
    r[0] = newsds
    cdef int count = PyOS_snprintf(newsds+sdslen(newsds), 20,"i%llde", data)
    # r.write(<bytes>buf[:count])
    sdsIncrLen(newsds, <int> count)

cdef int encode_bool(bint data, sds* r) except -1:
    if data:
        return encode_int(1, r)
    else:
        return encode_int(0, r)


cdef int encode_string(str data, sds* r) except -1:
    cdef Py_ssize_t size
    cdef const char* data_b = PyUnicode_AsUTF8AndSize(data, &size)
    # return encode_bytes(data.encode(), r)
    cdef sds newsds = sdsMakeRoomFor(r[0], <size_t> size + 30)
    if newsds == NULL:
        raise MemoryError
    r[0] = newsds
    count = PyOS_snprintf(newsds + sdslen(newsds), <size_t> size + 30, "%lld:", size)
    sdsIncrLen(newsds, count)
    memcpy(newsds + sdslen(newsds), data_b, <size_t> size)
    sdsIncrLen(newsds, <int> size)

cdef int encode_bytes(const uint8_t[::1] data, sds* r) except -1:
    cdef:
        Py_ssize_t size = data.shape[0]
        int count
    cdef sds newsds = sdsMakeRoomFor(r[0], <size_t>size + 30)
    if newsds == NULL:
        raise MemoryError
    r[0] = newsds
    count = PyOS_snprintf(newsds+sdslen(newsds), <size_t>size + 30, "%lld:", size)
    sdsIncrLen(newsds, count)
    # print(f"in encode_bytes, count = {count}")
    memcpy(newsds+sdslen(newsds), &data[0], <size_t>size)
    # r.write(<bytes>buf[:count+<int>size])
    sdsIncrLen(newsds, <int> size)
    # r.write(b''.join((str(len(data)).encode(), b':', data)))


cdef int encode_list(object data, sds* r) except -1: # object is list or tuple, so we use object here
    # r.write(b'l')
    cdef sds temp = sdscat(r[0], 'l')
    if temp == NULL:
        raise MemoryError
    r[0] = temp
    for i in data:
        encode_any(i, r)
    temp = sdscat(r[0], 'e')
    if temp == NULL:
        raise MemoryError
    r[0] = temp


cdef int encode_dict(dict data, sds* ret) except -1:
    cdef sds temp = sdscat(ret[0], 'd')
    if temp == NULL:
        raise MemoryError
    ret[0] = temp
    cdef list ilist = list(data.items()) # todo should we sort?
    ilist.sort()
    for key, v in ilist:
        # ret.write(b''.join((str(len(k)).encode(), b':', k.encode() if isinstance(k, str) else k)))
        if PyUnicode_Check(key):
            encode_string(key ,ret)
        else:
            encode_bytes(key, ret)
        encode_any(v, ret)
    temp = sdscat(ret[0], 'e')
    if temp == NULL:
        raise MemoryError
    ret[0] = temp

cdef int encode_any(object data, sds* ret) except -1: # dispatch types
    if PyLong_Check(data):
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
    elif type(data) == Bencached:
        encode_bencached(data, ret)  # this is not likely to happen
    else:
        raise ValueError(f"unsupported type {type(data)}")

# encode_func = {}
# encode_func[Bencached] = encode_bencached
# encode_func[int] = encode_int  # type: ignore
# encode_func[str] = encode_string  # type: ignore
# encode_func[bytes] = encode_bytes  # type: ignore
# encode_func[list] = encode_list  # type: ignore
# encode_func[tuple] = encode_list  # type: ignore
# encode_func[dict] = encode_dict  # type: ignore
# encode_func[bool] = encode_bool  # type: ignore


cpdef bytes bencode(object data, Py_ssize_t bufsize=100000):
    """
    bencode(data) -> bytes

    """
    cdef sds ret
    try:
        ret = sdsempty()
        if ret == NULL:
            raise MemoryError
        ret = sdsMakeRoomFor(ret, bufsize)
        if ret == NULL:
            raise MemoryError
        encode_any(data, &ret)
        return PyBytes_FromStringAndSize(ret, <Py_ssize_t>sdslen(ret))
    finally:
        sdsfree(ret)
