module vest

fn (mut self Module) internal_init() ! {
	if !self.is_init {
		self.is_init = true

		for mut mod in self.imports {
			mod.internal_init()!
		}

		for typ in self.services.keys() {
			self.services[typ].init()!
		}
	}
}

pub fn (mut self Module) init() ! {
	for mut global_mod in self.globals {
		global_mod.internal_inject()!
	}
	self.internal_inject()!

	for mut global_mod in self.globals {
		global_mod.internal_init()!
	}
	self.internal_init()!
}
