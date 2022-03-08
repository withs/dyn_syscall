module dyn_syscall

#include <windows.h>

fn C.GetProcAddress(C.HMODULE, &char) voidptr
fn C.GetModuleHandleA(&char) C.HMODULE
fn C.VirtualAlloc(voidptr, u16, u32, u32) voidptr
fn C.VirtualFree(voidptr, u16, u32) bool
