#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <glob.h>
#include <libgen.h>
#ifdef __linux__
#include <linux/limits.h>
#else
#include <limits.h>             /* PATH_MAX */
#endif
#include <pwd.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>

#include "ini.h"
/* #include "log.h" */
/* #if EXPORT_INTERFACE */
/* #include "utarray.h" */
/* #include "utstring.h" */
/* #endif */

#include "config_opam.h"

/* const char *errmsg = NULL; */

int rc;

/* char *bazel_script_dir = NULL; */

bool enable_jsoo = true;

UT_string *opam_switch_id       = NULL;

UT_string *opam_switch_prefix   = NULL;
UT_string *opam_coswitch_prefix = NULL;

UT_string *opam_switch_bin      = NULL;
UT_string *opam_coswitch_bin    = NULL;

UT_string *opam_switch_lib      = NULL;
UT_string *opam_coswitch_lib    = NULL;

/* seets global opam_switch_* vars */
EXPORT void opam_configure(char *_opam_switch)
{
#if defined(DEBUG_TRACE)
    if (trace)
        log_trace("opam_configure: '%s'", _opam_switch);
    log_trace("cwd: %s\n", getcwd(NULL, 0));
#endif

    /*
      if _opam_switch emtpy, discover current switch:
          - check for local switch ('_opam' subdir of root dir)
         - check env var OPAMSWITCH
         - else run 'opam var switch'
      2. discover lib dir: 'opam var lib'
     */

    utstring_new(opam_switch_id);
    utstring_new(opam_switch_prefix);
    utstring_new(opam_coswitch_prefix);
    utstring_new(opam_switch_bin);
    utstring_new(opam_coswitch_bin);
    utstring_new(opam_switch_lib);
    utstring_new(opam_coswitch_lib);

    /* FIXME: handle switch arg */
    /* FIXME: argv */
    char *exe = NULL, *result = NULL;
    if (strlen(_opam_switch) == 0) {

        exe = "opam";
        /* char *argv[] = {"opam", "var", "switch",NULL}; */
        char *argv[] = {"opam", "var", "ocaml:version", NULL};

        result = run_cmd(exe, argv);
        if (result == NULL) {
            fprintf(stderr, "FAIL: run_cmd 'opam var ocaml:version'\n");
        } else {
            utstring_printf(opam_switch_id, "%s", result);
            log_info("opam: using current switch: %s", result);

#if defined(DEBUG_TRACE)
            log_debug("cmd result: '%s'", utstring_body(opam_switch_id));
#endif
        }
    } // else??
    /* cmd = "opam var prefix"; */
    char *argv1[] = {"opam", "var", "prefix", NULL};
    result = NULL;
    result = run_cmd(exe, argv1);
    if (result == NULL) {
        log_fatal("FAIL: run_cmd 'opam var prefix'\n");
        exit(EXIT_FAILURE);
    } else {
        utstring_printf(opam_switch_prefix, "%s", result);
        /* default: coswitch == switch */
        utstring_printf(opam_coswitch_prefix, "%s", result);
#if defined(DEBUG_TRACE)
        log_debug("cmd result: '%s'", utstring_body(opam_switch_bin));
#endif
    }

    /* cmd = "opam var bin"; */
    char *argv2[] = {"opam", "var", "bin", NULL};
    result = NULL;
    result = run_cmd(exe, argv2);
    if (result == NULL) {
        log_fatal("FAIL: run_cmd 'opam var bin'\n");
        exit(EXIT_FAILURE);
    } else {
        utstring_printf(opam_switch_bin, "%s", result);
        /* default: coswitch == switch */
        utstring_printf(opam_coswitch_bin, "%s", result);
#if defined(DEBUG_TRACE)
        log_debug("cmd result: '%s'", utstring_body(opam_switch_bin));
#endif
    }

    /* cmd = "opam var lib"; */
    char *argv3[] = {"opam", "var", "lib", NULL};
    result = NULL;
    result = run_cmd(exe, argv3);
    if (result == NULL) {
        log_fatal("FAIL: run_cmd 'opam var lib'\n");
        exit(EXIT_FAILURE);
    } else {
        utstring_printf(opam_switch_lib, "%s", result);
        /* default: coswitch == switch */
        utstring_printf(opam_coswitch_lib, "%s", result);
#if defined(DEBUG_TRACE)
        log_debug("cmd result: '%s'", utstring_body(opam_switch_lib));
#endif
    }
    return;
}
