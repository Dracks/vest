module vest

struct SimpleService {
pub mut:
	count int
}



struct SomeServiceWithInjection {
pub:
	serv &SimpleService ['inject: .SimpleService']
}

fn set_up_module() !Module {
	mut mod := Module{}
	service := mod.register[SimpleService]() or {panic(err)}
	return mod
}

fn test_basic_registration(){
	mut mod := Module{}
	service := mod.register[SimpleService]() or {panic(err)}

	service_2 := mod.get[SimpleService]('.SimpleService') or { panic(err)}
	assert service == service_2
}

fn test_service_with_injection(){
	mut mod := set_up_module()!

	subject := mod.register[SomeServiceWithInjection]()!

	mod.get[SimpleService]('.SimpleService')!.count = 42

	assert subject.serv.count == 42
}
