#define _GNU_SOURCE // for RTLD_NEXT
#include <stdio.h>
#include <dlfcn.h>
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <stdarg.h>

#ifndef __APPLE__
#define ORIGINAL(name) original_##name
#define REPLACEMENT(name) name
#define OVERRIDE(ret, name, args) \
    static ret (*original_##name) args; \
    __attribute__((constructor)) void init_##name() { ORIGINAL(name) = dlsym(RTLD_NEXT, #name); } \
    ret REPLACEMENT(name) args

#define REPLACE(ret, name, args) \
    ret REPLACEMENT(name) args
#else
#define ORIGINAL(name) name
#define REPLACEMENT(name) new_##name
#define OVERRIDE(ret, name, args) \
    ret REPLACEMENT(name) args; \
    __attribute__((used)) static struct { const void *original; const void *replacement; } _interpose_##name \
    __attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&REPLACEMENT(name), (const void*)(unsigned long)&ORIGINAL(name) }; \
    ret REPLACEMENT(name) args

#define REPLACE(ret, name, args) OVERRIDE(ret, name, args)
#endif

static const char *priv_dir = NULL;

__attribute__((constructor)) void pppd_shim_init()
{
    priv_dir = getenv("PRIV_DIR");
}

static int fixup_path(const char *input, char *output)
{
    if (strncmp("/etc/", input, 5) == 0) {
        // Redirect everything in /etc to under our priv directory
        sprintf(output, "%s%s", priv_dir, input);
    } else {
        // No need to change the path.
        strcpy(output, input);
    }

    return 0;
}

// pppd first calls stat to check that the program in /etc/ppp exists
// and is executable. Then it calls execve. This shim only intercepts
// those two library calls and modifies them to point to our priv
// directory.

OVERRIDE(int, __xstat, (int ver, const char *pathname, struct stat *st))
{
    char new_path[PATH_MAX];
    if (fixup_path(pathname, new_path) < 0)
        return -1;

    return ORIGINAL(__xstat)(ver, new_path, st);
}

OVERRIDE(int, execve, (const char *file, char *const argv[], char *const envp[]))
{
    char new_path[PATH_MAX];
    if (fixup_path(file, new_path) < 0)
        return -1;

    return ORIGINAL(execve)(new_path, argv, envp);
}
