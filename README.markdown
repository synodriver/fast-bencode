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

raw = bdecode(data)
pprint(raw)

assert bencode(raw) == data
```
- There are alias function ```loads``` for ```bdecode``` and ```dumps``` for ```bencode```


### build
```bash
git clone https://github.com/synodriver/fast-bencode.git
cd fast-bencode
python setup.py build_ext -i
```
