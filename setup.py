# -*- coding: utf-8 -*-
import sys
from collections import defaultdict

from setuptools import Extension, find_packages, setup  # type: ignore
from setuptools.command.build_ext import build_ext  # type: ignore

try:
    from Cython.Build import cythonize  # type: ignore
    from Cython.Compiler.Version import version as cython_version
    from packaging.version import Version

    has_cython = True
except ImportError:
    has_cython = False

if (
    sys.version_info > (3, 13, 0)
    and hasattr(sys, "_is_gil_enabled")
    and not sys._is_gil_enabled()
):
    print("build nogil")
    defined_macros = [
        ("Py_GIL_DISABLED", "1"),
    ]  # ("CYTHON_METH_FASTCALL", "1"), ("CYTHON_VECTORCALL",  1)]
else:
    defined_macros = []

ext_modules = [
    Extension(
        "bencode._bencode",
        sources=["bencode/_bencode.pyx", "bencode/util.c", "bencode/sds.c"],
        include_dirs=["bencode"],
        define_macros=defined_macros,
    )
]

BUILD_ARGS = defaultdict(lambda: ["-O3", "-g0"])  # type: ignore
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


compiler_directives = {
    "cdivision": True,
    "embedsignature": True,
    "boundscheck": False,
    "wraparound": False,
}


if Version(cython_version) >= Version("3.1.0a0"):
    compiler_directives["freethreading_compatible"] = True

setup(
    name="fast-bencode",
    version="1.1.7",
    packages=find_packages(exclude=("test", "tests.*", "test*")),
    ext_modules=(
        cythonize(ext_modules, compiler_directives=compiler_directives)
        if has_cython
        else None
    ),
    author="synodriver",
    author_email="diguohuangjiajinweijun@gmail.com",
    description="Bencode and decode for python",
    license="BitTorrent Open Source License",
    keywords="bittorrent bencode bdecode",
    url="https://github.com/synodriver/fast-bencode",
    zip_safe=True,
    include_package_data=True,
    python_requires=">=3.8",
    setup_requires=["Cython>=3.0.9"],
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Operating System :: OS Independent",
        "Programming Language :: Cython",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Programming Language :: Python :: Implementation :: CPython",
    ],
    cmdclass={"build_ext": build_ext_compiler_check} if has_cython else {},
    long_description=get_dis(),
    long_description_content_type="text/markdown",
)
