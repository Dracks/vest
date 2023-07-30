module vest

struct SomeServiceWithInjection {
	service   &SimpleService [inject]
	with_name &SimpleService [inject: SimpleService]
}

struct SimpleServiceInstance {
	text string
}

struct SomeServiceWithOnlyTypeInject {
	service &SimpleServiceInstance [inject]
}

fn test_parent_can_inject_children() ! {
	mut subject := Module{}
	mut mod := set_up_module()
	subject.import_module(mut mod)
	subject.register[SomeServiceWithInjection]()

	subject.init()!

	simple_service := mod.get[SimpleService](none)!
	assert simple_service.text == 'Hello world'
}

fn test_global_module() ! {
	mut sub_mod1 := Module{
		global: true
	}
	sub_mod1.register_and_export[SimpleService]()

	mut mod := Module{}
	mod.import_module(mut sub_mod1)

	mut sub_mod2 := Module{}
	mod.import_module(mut sub_mod2)
	sub_mod2.register[SomeServiceWithInjection]()

	mod.init()!

	simple_service := mod.get[SimpleService](none)!
	assert simple_service.text == 'Hello world'
}

fn test_import_nonexported_service() ! {
	mut sub_mod1 := Module{
		global: true
	}
	sub_mod1.register[SimpleService]()

	mut mod := Module{}
	mod.import_module(mut sub_mod1)

	mut sub_mod2 := Module{}
	mod.import_module(mut sub_mod2)
	sub_mod2.register[SomeServiceWithInjection]()

	mod.init() or {
		assert err.msg() == 'Invalid injection type for field service in .SomeServiceWithInjection'
		return
	}

	assert false
}

fn test_use_instance() ! {
	mut mod := Module{}
	simple := SimpleServiceInstance{
		text: 'Daleks'
	}

	mod.use_instance(simple, false)
	mod.register[SomeServiceWithOnlyTypeInject]()

	mod.init()!

	service := mod.get[SomeServiceWithOnlyTypeInject](none)!
	assert simple.text == 'Daleks'
	assert service.service.text == 'Daleks'
}

struct EmptyObject {}

fn test_use_factory_with_simple_object() ! {
	mut mod := Module{}
	mod.use_factory(fn (dep EmptyObject) SimpleServiceInstance {
		return SimpleServiceInstance{ text: 'We use a factory!' }
	}, false)

	mod.init()!

	service := mod.get[SimpleServiceInstance](none)!
	assert service.text == 'We use a factory!'
}
