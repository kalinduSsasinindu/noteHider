// native_integrity.h
#ifndef NATIVE_INTEGRITY_H
#define NATIVE_INTEGRITY_H
#include <stdint.h>

// Bit-flags returned by quick_probe_native()
#define INTEGRITY_DEBUGGER_ATTACHED   0x01
#define INTEGRITY_SU_BINARY_FOUND     0x02
#define INTEGRITY_FRIDA_DETECTED      0x04
#define INTEGRITY_PLAY_VERDICT_FAIL   0x08
// Extended checks
#define INTEGRITY_SELINUX_PERMISSIVE   0x10
#define INTEGRITY_MAGISK_DETECTED     0x20
#define INTEGRITY_XPOSED_DETECTED     0x40
// 0x10  SELinux is in permissive mode (enforcing expected)
// 0x20  Magisk systemless root or its mountpoints detected
// 0x40  Xposed / LSPosed or similar hooking framework detected
// Add more flags as needed.

#ifdef __cplusplus
extern "C" {
#endif

// Returns a bitmask whose non-zero bits indicate integrity violations.
uint32_t quick_probe_native();

// Kotlin/Java layer should call this with 1 = passed, 0 = failed
void set_play_integrity_status(int ok);

#ifdef __cplusplus
}
#endif

#endif // NATIVE_INTEGRITY_H 