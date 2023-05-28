module vest

struct SimpleService {
pub mut:
	text string = ""
}

struct SomeServiceWithInjection {
	service &SimpleService [inject]
	with_name &SimpleService [inject: SimpleService]
}

fn set_up_module() &Module {
	mut mod := &Module{}
	service := mod.register[SimpleService]()
	return mod
}

fn test_parent_can_inject_children() ! {
	// mut child := set_up_module
	assert true
}
