#include "native_integrity.h"
#include <errno.h>
#if defined(__ANDROID__) || defined(__linux__)
#include <sys/ptrace.h>
#include <sys/stat.h>
#else
#include <sys/stat.h>
static inline long ptrace(int request, ...) { (void)request; errno = EPERM; return -1; }
#endif
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <stdlib.h>

#if !defined(PTRACE_TRACEME)
#define PTRACE_TRACEME 0
#endif
#if !defined(PTRACE_DETACH)
#define PTRACE_DETACH 17
#endif

static volatile int _playIntegrityOK = 1; // 1 = passed by default
void set_play_integrity_status(int ok) { _playIntegrityOK = ok; }

static int _is_debugger_attached() {
    // Attempt to ptrace self; if EPERM -> already traced.
    if (ptrace(PTRACE_TRACEME, 0, NULL, NULL) == -1) {
        return errno == EPERM;
    }
    ptrace(PTRACE_DETACH, 0, NULL, NULL);
    return 0;
}

static int _file_exists(const char *path) {
    struct stat st;
    return stat(path, &st) == 0;
}

static int _has_su_binary() {
    const char *su_paths[] = {
        "/system/bin/su", "/system/xbin/su", "/sbin/su",
        "/vendor/bin/su", "/su/bin/su", NULL};
    for (int i = 0; su_paths[i]; ++i) {
        if (_file_exists(su_paths[i])) return 1;
    }
    return 0;
}

static int _frida_server_present() {
    const char *paths[] = {
        "/data/local/tmp/frida-server", "/data/local/frida-server",
        "/system/bin/frida-server", NULL};
    for (int i = 0; paths[i]; ++i) {
        if (_file_exists(paths[i])) return 1;
    }
    return 0;
}

// Check if SELinux is enforcing (0 = permissive, 1 = enforcing)
static int _selinux_permissive() {
#ifdef COMMENT
/*
 * Returns 1 when the device runs with SELinux set to Permissive mode – a
 * strong indicator of a compromised security posture.  For performance and
 * portability we simply read the one-byte flag from
 *   /sys/fs/selinux/enforce  ("1" = enforcing, "0" = permissive).
 * On non-Linux platforms the check is skipped.
 */
#endif
#if defined(__ANDROID__) || defined(__linux__)
    FILE *f = fopen("/sys/fs/selinux/enforce", "r");
    if (!f) return 1; // Treat unknown as permissive (unsafe)
    int ch = fgetc(f);
    fclose(f);
    return (ch == '0');
#else
    return 0; // Not applicable
#endif
}

static int _magisk_present() {
    return _file_exists("/sbin/.magisk") || _file_exists("/data/adb/magisk");
}

static int _xposed_present() {
    const char *paths[] = {
        "/system/bin/app_process64_xposed", "/system/framework/XposedBridge.jar",
        "/system/lib/libxposed.so", NULL};
    for (int i = 0; paths[i]; ++i) {
        if (_file_exists(paths[i])) return 1;
    }
    return 0;
}

uint32_t quick_probe_native() {
    uint32_t flags = 0;
    if (_is_debugger_attached()) flags |= INTEGRITY_DEBUGGER_ATTACHED;
    if (_has_su_binary())       flags |= INTEGRITY_SU_BINARY_FOUND;
    if (_frida_server_present()) flags |= INTEGRITY_FRIDA_DETECTED;
    if (!_playIntegrityOK)      flags |= INTEGRITY_PLAY_VERDICT_FAIL;
    if (_selinux_permissive())  flags |= INTEGRITY_SELINUX_PERMISSIVE;
    if (_magisk_present())      flags |= INTEGRITY_MAGISK_DETECTED;
    if (_xposed_present())      flags |= INTEGRITY_XPOSED_DETECTED;
    return flags;
} 