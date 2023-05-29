module vest

[provide: DifferentName]
pub struct SimpleService {
pub mut:
	count   int
	text    string
	boolean bool
}

pub fn (mut self SimpleService) on_init()! {
	self.count = 33
	self.text = "Hello world"
	self.boolean = true
}

pub fn set_up_module() Module {
	mut mod := Module{}
	mod.register[SimpleService]()
	return mod
}