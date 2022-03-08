prod:
	v -os windows -prod -shared .
debug:
	v -cg -os windows -shared .
dbc:
	v -cg -os windows -shared .
test:
	v test tests/
fmt:
	v fmt -w .
doc:
	v doc -f html -o . -inline-assets -m .
install:
	rm -r ~/.vmodules/dyn_syscall && mkdir ~/.vmodules/dyn_syscall && cp -r * ~/.vmodules/dyn_syscall
