module vest

interface SomeInterface {
mut:
	count int
}

struct SomeServiceWithInjection {
pub:
	serv        &SimpleService [inject]
	custom_name &SimpleService [inject: DifferentName]
}

struct ServiceWithInterface {
pub:
	serv SomeInterface ['inject: vest.SimpleService']
}

struct ServiceWithoutReference {
pub:
	serv SomeInterface ['inject: vest.SimpleService']
}

fn test_basic_registration() ! {
	mut mod := Module{}
	service := mod.register[SimpleService]()

	service_2 := mod.get[SimpleService](none) or { panic(err) }
	assert service == service_2
}

fn test_service_with_injection() ! {
	mut mod := set_up_module()

	subject := mod.register[SomeServiceWithInjection]()
	mod.init() or { panic(err) }

	mut service := mod.get[SimpleService]('vest.SimpleService')!
	service.count = 42

	assert subject.serv.count == 42
}

fn test_service_injection_with_custom_name() ! {
	mut mod := set_up_module()

	subject := mod.register[SomeServiceWithInjection]()

	mod.init() or { panic(err) }
	mut serv := subject.serv

	serv.count = 42

	assert subject.custom_name.count == 42
}

fn test_service_with_initialization() ! {
	mut mod := set_up_module()

	mod.init()!

	service := mod.get[SimpleService]('DifferentName')!
	assert service.count == 33
}

fn test_get_wrong_name() ! {
	mut mod := set_up_module()

	mod.get[SimpleService]('Name') or {
		assert err.msg() == "Service with name Name not available, see available: ['vest.SimpleService', 'DifferentName']"
		return
	}
	assert false
}

fn test_service_with_interface() ! {
	mut mod := set_up_module()
	mod.register[ServiceWithInterface]()

	mod.init() or {
		assert err.msg() == "Type of property 'serv' in 'vest.ServiceWithInterface' must be vest.SimpleService as Reference"
		return
	}
	assert false
}

fn test_service_without_reference() ! {
	mut mod := set_up_module()
	mod.register[ServiceWithoutReference]()

	mod.init() or {
		assert err.msg() == "Type of property 'serv' in 'vest.ServiceWithoutReference' must be vest.SimpleService as Reference"
		return
	}
	assert false
}
