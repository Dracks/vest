module vest

struct SomeObject {
	serv &SimpleService @[inject]
}

fn test_injecting_to_external_object() {
	mut subject := SomeObject{}
	mut mod := set_up_module()
	mod.inject_to_object(mut subject)!

	assert subject.serv == mod.get[SimpleService](none)!
}
