# -*- coding: utf-8 -*-
from collections import defaultdict

from setuptools import Extension, find_packages, setup
from setuptools.command.build_ext import build_ext

try:
    from Cython.Build import cythonize

    has_cython = True
except ImportError:
    has_cython = False

ext_modules = [
    Extension(
        "bencode._bencode",
        sources=["bencode/_bencode.pyx", "bencode/util.c", "bencode/sds.c"],
        include_dirs=["bencode"],
    )
]

BUILD_ARGS = defaultdict(lambda: ["-O3", "-g0"])
for compiler, args in [
    ("msvc", ["/EHsc", "/DHUNSPELL_STATIC", "/Oi", "/O2", "/Ot"]),
    ("gcc", ["-O3", "-g0"]),
]:
    BUILD_ARGS[compiler] = args


class build_ext_compiler_check(build_ext):
    def build_extensions(self):
        compiler = self.compiler.compiler_type
        args = BUILD_ARGS[compiler]
        for ext in self.extensions:
            ext.extra_compile_args = args
        super().build_extensions()


def get_dis():
    with open("README.markdown", "r", encoding="utf-8") as f:
        return f.read()


setup(
    name="fast-bencode",
    version="1.1.4",
    packages=find_packages(exclude=("test", "tests.*", "test*")),
    ext_modules=cythonize(
        ext_modules,
        compiler_directives={
            "cdivision": True,
            "embedsignature": True,
            "boundscheck": False,
            "wraparound": False,
        },
    )
    if has_cython
    else None,
    author="synodriver",
    author_email="diguohuangjiajinweijun@gmail.com",
    description="Bencode and decode for python",
    license="BitTorrent Open Source License",
    keywords="bittorrent bencode bdecode",
    url="https://github.com/synodriver/fast-bencode",
    zip_safe=True,
    include_package_data=True,
    python_requires=">=3.6",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Operating System :: OS Independent",
        "Programming Language :: Cython",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: Implementation :: CPython",
    ],
    cmdclass={"build_ext": build_ext_compiler_check} if has_cython else None,
    long_description=get_dis(),
    long_description_content_type="text/markdown",
)
