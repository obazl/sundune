##########
def mibl(name = "mibl", main = None, args = None, **kwargs):
    if main:
        _args = ["-m", main]
    else:
        _args = []

    if args:
        _args.extend(args)

    # native.genrule(
    #     name = "mkhdrs",
    #     srcs = ["//mibl:mibl.c"],
    #     outs = ["mibl.h"],
    #     cmd = "\n".join([
    #         "SRC1=$(location //mibl:mibl.c)",
    #         "SRCDIR1=`dirname $$SRC1`",
    #         "$(location //vendored/makeheaders) \\",
    #         "    $(location //mibl:mibl.c);",
    #         "cp $${SRCDIR1}/*.h $(@D)",
    #     ]),
    #     tools = ["//vendored/makeheaders"],
    #     visibility = ["//visibility:public"]
    # )

    native.cc_binary(
        name  = name,
        args  = _args,
        data = [
            "//scm:srcs",
            "//scm/dune:srcs",
            "//scm/meta:srcs",
            "//scm/opam:srcs",
        ],
        srcs  = ["//mibl:mibl.c", "//mibl:mibl.h"],
        linkstatic = True,
        defines = select({
            "//bzl/host:debug": ["DEBUG_TRACE"],
            "//conditions:default":   []
        }) + select({
            "//bzl/host:linux": ["_XOPEN_SOURCE=500"], # strdup
            "//conditions:default":   []
        }) + [
            # "WITH_C_LOADER"
        ],
        copts = select({
            "//bzl/host:macos": ["-std=c11"],
            "//bzl/host:linux": ["-std=gnu11"],
            "//conditions:default": ["-std=c11"],
        }) + [
            "-Wall",
            "-Werror",
            "-Wpedantic",
            "-Wno-unused-function",

            # any target that
            "-I$(GENDIR)/debug",               # mibl.h
            "-I$(GENDIR)/mibl",               # mibl.h
            "-I$(GENDIR)/external/mibl/mibl",

            "-I$(GENDIR)/src/hdrs",                # libmibl.h
            "-I$(GENDIR)/external/mibl/src/hdrs",

            "-Ivendored/gopt",
            "-Iexternal/mibl/vendored/gopt",

            "-Ivendored/libinih",
            "-Iexternal/mibl/vendored/libinih",

            "-Ivendored/logc",
            "-Iexternal/mibl/vendored/logc",

            "-Ivendored/uthash",
            "-Iexternal/mibl/vendored/uthash",

            "-Iexternal/libs7/src", # loaded by @mibl//src:mibl
        ],
        linkopts = select({
            "//bzl/host:macos": [],
            "//bzl/host:linux": ["-ldl", "-lm"],
            "//conditions:default": {}
        }),
        deps = [
            "@mibl//src:mibl",
            "@mibl//vendored/gopt",
            "@mibl//vendored/libinih:inih",
            "@mibl//vendored/logc",
            "@mibl//vendored/uthash",
        ],
        visibility = ["//visibility:public"]
    )
