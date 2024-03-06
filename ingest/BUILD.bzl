load("@bazel_skylib//lib:dicts.bzl", "dicts")

# load("//:BUILD.bzl",
#      "GOPT_VERSION",
#      # "INIH_VERSION",
#      "LIBLOGC_VERSION")

# rules:

## mibl_runner - runs mibl as build action (like a compiler)

## run_mibl - wraps mibl in an executable, to support bazel run cmds
## with varying args. We can 'bazel run mibl' and pass cmd line args,
## but if we want to define some canned cmds we must either build one
## mibl executable per cmd, or define a wrapper.

## For example, say we want target //dev:foo to run mibl with args
## --foo --bar etc. I.e. we want to encapsulate 'bazel run mibl --
## --foo --bar ...' in a single target, so we can run 'bazel run
## dev:foo'.

## One way to do this is to use a macro that generates a custom build
## of mibl. See below for an example. A drawback of this is that we
## then must build mibl once per target.

## An alternative is to define an executable target whose
## sole purpose is to run the mibl executable with the specified
## args.

## This is fairly easy to do using skylibs sh_binary rule; see the
## example here, in mibl/BUILD.bazel and mibl/run_mibl.sh. The problem
## with this is that it is not portable, since it depends on shell
## processing.

## Skylib also has a 'native_binary' rule.


def _run_mibl_impl(ctx):
    tool_as_list = [ctx.attr._tool]
    tool_inputs, tool_input_mfs = ctx.resolve_tools(tools = tool_as_list)
    args = [
        ctx.expand_location(a, tool_as_list) if "$(location" in a else a
        for a in ctx.attr.args
    ]
    # print("Gendir: %s" % ctx.var["GENDIR"])
    # args.append("--gendir")
    # args.append(ctx.var["GENDIR"])
    envs = {
        # Expand $(location) / $(locations) in the values.
        k: ctx.expand_location(v, tool_as_list) if "$(location" in v else v
        for k, v in ctx.attr.env.items()
    }
    # print("OUTPUTS: %s" % ctx.outputs.outs)
    # for o in ctx.outputs.outs:
    #     print("O: %s" % o.path)

    ## RUNFILES: the tool executable (always mibl.exe) carries its
    ## libs7/scm runfiles, so we need to add those as inputs to the
    ## action.
    ctx.actions.run(
        outputs = [], # ctx.outputs.outs,
        inputs = ctx.attr._tool[DefaultInfo].data_runfiles.files.to_list(),
        tools = tool_inputs,
        executable = ctx.executable._tool,
        arguments = args,
        mnemonic = "RunMibl",
        use_default_shell_env = False,
        env = dicts.add(ctx.configuration.default_shell_env, envs),
        input_manifests = tool_input_mfs,
    )

    return DefaultInfo(
        files = depset(ctx.outputs.outs),
        runfiles = ctx.runfiles(
            files = ctx.outputs.outs,
            # transitive_files = ctx.attr.tool[DefaultInfo].data_runfiles.files
        ),
    )

################
run_mibl = rule(
    implementation = _run_mibl_impl,
    doc = "Runs mibl executable as a build action.\n\nThis rule does not require Bash (unlike" +
          " `native.genrule`).",
    attrs = {
        "_tool": attr.label(
            executable = True,
            allow_files = True,
            ## mandatory = True,
            default = "//mibl",
            cfg = "exec",
        ),
        "env": attr.string_dict(
            doc = "Environment variables of the action.\n\nSubject to " +
                  " [`$(location)`](https://bazel.build/reference/be/make-variables#predefined_label_variables)" +
                  " expansion.",
        ),
        # "srcs": attr.label_list(
        #     allow_files = True,
        #     doc = "Additional inputs of the action.\n\nThese labels are available for" +
        #           " `$(location)` expansion in `args` and `env`.",
        # ),
        # "outs": attr.output_list(
        #     mandatory = True,
        #     doc = "Output files generated by the action.\n\nThese labels are available for" +
        #           " `$(location)` expansion in `args` and `env`.",
        # ),
        "args": attr.string_list(
            doc = "Command line arguments of the binary.\n\nSubject to" +
                  " [`$(location)`](https://bazel.build/reference/be/make-variables#predefined_label_variables)" +
                  " expansion.",
        ),
    },
)

################################################################
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
    #         "$(execpath @makeheaders//src:makeheaders) \\",
    #         "    $(location //mibl:mibl.c);",
    #         "cp $${SRCDIR1}/*.h $(@D)",
    #     ]),
    #     tools = ["@makeheaders//src:makeheaders"],
    #     visibility = ["//visibility:public"]
    # )

    native.cc_binary(
        name  = name,
        args  = _args,
        data = [
            "//scm:srcs",
            "//scm/dune:srcs",
            "//scm/findlib:srcs",
            "//scm/opam:srcs",
        ],
        srcs  = [
            "//mibl:mibl.c", "//mibl:mibl.h",
        ],
        linkstatic = True,
        defines = select({
            "//bzl/host:debug": ["TRACING"],
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

            "-I$(GENDIR)/src/hdrs",                # mibl.h
            "-I$(GENDIR)/external/mibl/src/hdrs",

            # "-Iexternal/gopt~{}".format(GOPT_VERSION),
            # "-Ivendored/gopt",

            # "-Iexternal/inih~{}".format(INIH_VERSION),
            # "-Ivendored/libinih",

            # "-Iexternal/liblogc~{}/src".format(LIBLOGC_VERSION),

            "-Ivendored/uthash",
            "-Iexternal/mibl/vendored/uthash",

            "-Iexternal/libs7/src", # loaded by @mibl//src:mibl

            ## repl
            "-Iexternal/libs7/vendored/linenoise",
            "-Iexternal/mibl/libs7/vendored/linenoise",

        ],
        linkopts = select({
            "//bzl/host:macos": [],
            "//bzl/host:linux": ["-ldl", "-lm"],
            "//conditions:default": {}
        }),
        deps = [
            "//src:mibl",
            "@gopt//src:gopt",
            # "@inih//:inih",
            "@liblogc//src:logc",
            "@mibl//vendored/uthash",
        ],
        visibility = ["//visibility:public"]
    )