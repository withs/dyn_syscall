import dyn_syscall

#include <windows.h>

fn C.GetCurrentProcessId() u32
fn C.OpenProcess(u32, bool, u32) C.HANDLE
fn C.GetLastError() u32
fn C.ReadProcessMemory(voidptr, voidptr, voidptr, u16, &u32) u32

type ZwReadVirtualMemory_t = fn (voidptr, voidptr, voidptr, u32, &u32) u32

type ZwWriteVirtualMemory_t = fn (voidptr, voidptr, voidptr, u32, &u32) u32

const zz = dyn_syscall.new_const_with_precached_fns([
	dyn_syscall.Fn{ with_name: 'ZwReadVirtualMemory', in_module: 'ntdll.dll' },
])

fn test_zw_invalid_fn() {
	mut z := dyn_syscall.DynSyscall{}
	defer {
		z.release()
	}

	z.cache('hi', 'ntdll.dll') or { println(err) }
}

fn test_zw_invalid_module() {
	mut z := dyn_syscall.DynSyscall{}
	defer {
		z.release()
	}

	z.cache('ZwReadVirtualMemory', 'hi.dll') or { println(err) }
}

fn test_const_precached() {
	zw_rm := zz.get<ZwReadVirtualMemory_t>('ZwReadVirtualMemory')

	dump(zz)
}

fn test_zw_read_mem() {
	mut z := dyn_syscall.DynSyscall{}
	z.cache('ZwReadVirtualMemory', 'ntdll.dll') or { println(err) }
	zw_rm := z.get<ZwReadVirtualMemory_t>('ZwReadVirtualMemory')

	dump(z)
	// read local process

	mut handle := C.OpenProcess(u32(C.PROCESS_ALL_ACCESS), false, C.GetCurrentProcessId())

	to_read := u32(667)
	to_read_buff := []u32{len: 1}
	to_read_bytes_readed := u32(0)

	nt_ret := zw_rm(voidptr(handle), &to_read, to_read_buff.data, sizeof(to_read), &to_read_bytes_readed)

	assert nt_ret == 0
	assert to_read_bytes_readed == sizeof(to_read)
	assert to_read_buff[0] == to_read

	dump(nt_ret)
	dump(to_read_bytes_readed)
	dump(to_read_buff)
}

fn test_zw_write_mem() {
	mut z := dyn_syscall.DynSyscall{}
	z.cache('NtWriteVirtualMemory', 'ntdll.dll') or { println(err) }
	zw_wm := z.get<ZwWriteVirtualMemory_t>('NtWriteVirtualMemory')

	dump(z)
	// read local process

	mut handle := C.OpenProcess(u32(C.PROCESS_ALL_ACCESS), false, C.GetCurrentProcessId())

	to_write := u32(667)
	to_write_buff := []u32{len: 1, init: 670}
	to_write_bytes_written := u32(0)

	nt_ret := zw_wm(voidptr(handle), &to_write, to_write_buff.data, sizeof(to_write),
		&to_write_bytes_written)

	assert nt_ret == 0
	assert to_write_bytes_written == sizeof(to_write)
	assert to_write_buff[0] == to_write

	dump(nt_ret)
	dump(to_write_bytes_written)
	dump(to_write)
}

/*
fn main() {
	const_precached() // ok
	zw_invalid_module() // ok
	zw_invalid_fn() // OK
	zw_read_mem() // OK
	zw_write_mem() // OK

	zz.release()
}*/
