module vest

interface SomeInterface {
mut:
	count int
}

[provide: Name]
struct SimpleService{
pub mut:
	count int
}

pub fn (mut self SimpleService) on_init()! {
	println('On init!')
	self.count = 33
}

struct SomeServiceWithInjection {
pub:
	serv &SimpleService [inject]
	custom_name &SimpleService [inject: Name]
}

struct ServiceWithInterface {
pub: 
	serv SomeInterface [inject: SimpleService]
}

struct ServiceWithoutReference {
pub: 
	serv SomeInterface [inject: SimpleService]
}

fn set_up_module() &Module {
	mut mod := &Module{}
	service := mod.register[SimpleService]()
	return mod
}

fn test_basic_registration()!{
	mut mod := Module{}
	service := mod.register[SimpleService]()

	service_2 := mod.get[SimpleService](none) or { panic(err)}
	assert service == service_2
}

fn test_service_with_injection()!{
	mut mod := set_up_module()

	subject := mod.register[SomeServiceWithInjection]()
	mod.inject() or { panic(err)}

	mut service := mod.get[SimpleService]('SimpleService')!
	service.count = 42

	assert subject.serv.count == 42
}

fn test_service_injection_with_custom_name()!{
	mut mod := set_up_module()

	subject := mod.register[SomeServiceWithInjection]()

	mod.inject() or { panic(err)}
	mut serv := subject.serv

	serv.count = 42
   
	assert subject.custom_name.count == 42
}

fn test_service_with_initialization()!{
	mut mod := set_up_module()

	mod.init()!

	service := mod.get[SimpleService]('Name')!
	assert service.count == 33
}

fn test_service_with_interface()!{
	mut mod := set_up_module()
	mod.register[ServiceWithInterface]()

	mod.inject() or {
		println(err)
		return
	}
	assert false
}

fn test_service_without_reference()!{
	mut mod := set_up_module()
	mod.register[ServiceWithoutReference]()

	mod.inject() or {
		println(err)
		return
	}
	assert false
}
