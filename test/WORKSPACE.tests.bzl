skylib_ws = r"""
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_skylib",
    sha256 = "b8a1527901774180afc798aeb28c4634bdccf19c4d98e7bdd1ce79d1fe9aaad7",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz",
    ],
)
        """

#################
def test_repos():

    native.new_local_repository(
        name = "test.dune.actions.cmp",
        path = "test/dune/actions/cmp",
        build_file = "@//test/dune/actions/cmp:BUILD.bazel",
        workspace_file_content = skylib_ws
    )

    native.new_local_repository(
        name = "test.dune.actions.copy",
        path = "test/dune/actions/copy",
        build_file = "@//test/dune/actions/copy:BUILD.bazel",
        workspace_file_content = skylib_ws
    )

    native.new_local_repository(
        name = "test.dune.actions.diff",
        path = "test/dune/actions/diff",
        build_file = "@//test/dune/actions/diff:BUILD.bazel",
        workspace_file_content = skylib_ws
    )

    native.new_local_repository(
        name = "test.dune.executable.main_dyad_prologue",
        path = "test/dune/executable/main_dyad_prologue",
        build_file = "@//test/dune/executable/main_dyad_prologue:BUILD.bazel",
        workspace_file_content = skylib_ws
    )