module dyn_syscall

// cached syscalls holders
pub struct DynSyscall {
mut:
	cached_fns map[string]voidptr
}

// syscall data struct to cache many
pub struct Fn {
pub:
	with_name string [required]
	in_module string [required]
}

// cache a syscall.
// note: don't use is DynSyscall syscall is created with new_const_with_precached_fns.
// Example:
// ```v
// mut x := dyn_syscall.DynSyscall{}
// x.cache("ZwReadVirtualMemory", "ntdll.dll")
// ```
pub fn (mut d DynSyscall) cache(func string, fromModule string) ? {
	mut code := [u8(0x4C), 0x8B, 0xD1, 0xB8, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x05, 0xC3]

	module_handle := C.GetModuleHandleA(&char(fromModule.str))
	if int(module_handle) == 0 {
		return error('null handle returned by GetModuleHandleA for module $fromModule')
	}
	fn_addr := C.GetProcAddress(module_handle, &char(func.str))

	if fn_addr == 0 {
		return error('null address returned by GetProcAddress for function $func in module $fromModule')
	}

	mut fn_code := []u8{len: 11}

	unsafe {
		C.memcpy(fn_code.data, fn_addr, 11)
	}

	for i in 0 .. 4 {
		if fn_code[i] != code[i] {
			return error('pattern dont match syscall')
		}
	}

	code[4] = fn_code[4]

	syscall_func_addr := C.VirtualAlloc(0, 11, u32(C.MEM_COMMIT | C.MEM_RESERVE), C.PAGE_EXECUTE_READWRITE)

	unsafe {
		C.memcpy(syscall_func_addr, code.data, 11)
	}

	d.cached_fns[func] = syscall_func_addr
}

// cache many syscall.
// note: don't use is DynSyscall syscall is created with new_const_with_precached_fns.
// Example:
// ```v
// mut x := dyn_syscall.DynSyscall{}
// x.cache_many([dyn_syscall.Fn{with_name: "ZwReadVirtualMemory", in_module: "ntdll.dll"}, dyn_syscall.Fn{with_name: "ZwWriteVirtualMemory", in_module: "ntdll.dll"}])
// ```
pub fn (mut d DynSyscall) cache_many(withFns []Fn) {
	for func in withFns {
		if func.with_name in d.cached_fns {
			println('already cached')
		}

		d.cache(func.with_name, func.in_module) or {
			panic('cannot cache this function error: $err')
		}
	}
}

// return a cached syscall.
// Example:
// ```v
// type ZwReadVirtualMemory_t = fn (voidptr, voidptr, voidptr, u32, &u32) u32
// mut x := dyn_syscall.DynSyscall{}
// zw_rvm = x.get<ZwReadVirtualMemory_t>("ZwReadVirtualMemory")
// zw_rvm(args)
// ```
pub fn (d DynSyscall) get<T>(fnWithName string) T {
	if fnWithName !in d.cached_fns {
		error('function with name: $fnWithName is not cached')
	}

	return T(d.cached_fns[fnWithName])
}

// release alocated memory used to store syscalls shellcodes.
pub fn (d DynSyscall) release() {
	for _, a in d.cached_fns {
		C.VirtualFree(a, 11, u32(C.MEM_RELEASE))
	}
}

// return a DynSyscall object with precached syscalls, usefull if you want to use it with const.
// note: you cannot cache more syscalls than you specified in the array.
// Example:
// ```v
// const zz = dyn_syscall.new_const_with_precached_fns([dyn_syscall.Fn{with_name: "ZwReadVirtualMemory", in_module: "ntdll.dll"}])
// ```
pub fn new_const_with_precached_fns(withFns []Fn) DynSyscall {
	mut d := DynSyscall{}

	for f in withFns {
		d.cache(f.with_name, f.in_module) or { panic('cannot cache this function error: $err') }
	}

	return d
}
