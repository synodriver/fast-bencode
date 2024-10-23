<h1 align="center"><i>✨ fast-bencode ✨ </i></h1>

<h3 align="center">The cython version of bencode</a> </h3>

[![pypi](https://img.shields.io/pypi/v/fast-bencode.svg)](https://pypi.org/project/fast-bencode/)
![python](https://img.shields.io/pypi/pyversions/fast-bencode)
![implementation](https://img.shields.io/pypi/implementation/fast-bencode)
![wheel](https://img.shields.io/pypi/wheel/fast-bencode)
![license](https://img.shields.io/github/license/synodriver/fast-bencode.svg)
![action](https://img.shields.io/github/workflow/status/synodriver/fast-bencode/run%20unitest)

### forked from [bencode](https://github.com/bittorrent/bencode) to support latest version of python

- extra cython extension to speedup
- ```typing``` with mypy check

### Usage

```python
from pprint import pprint
from bencode import bdecode, bencode

with open("test.torrent", "rb") as f:
    data = f.read()

raw = bdecode(data, decode=False) # do not decode bytes to str, use this to speedup. default is True
pprint(raw)

assert bencode(raw, bufsize=1000000) == data # customize buffer size(in bytes) to speedup, this reduces call to realloc
```
- There are alias function ```loads``` for ```bdecode``` and ```dumps``` for ```bencode```
- ```load``` and ```dump``` are useful for file-like object
```python
from pprint import pprint
from bencode import load, dumps, loads, dumps

with open("test.torrent", "rb") as f:
    data = load(f, decode=False)

pprint(data)

print(dumps(data, bufsize=1000000))
```

### build
git clone https://github.com/synodriver/fast-bencode.git
cd fast-bencode
python setup.py build_ext -i
```
