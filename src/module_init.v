module vest

fn (mut self Module) internal_init() ! {
	if !self.is_init {
		self.is_init = true

		for mut mod in self.imports {
			mod.internal_init()!
		}

		for typ in self.services.keys() {
			if mut service := self.services[typ] {
				service.init()!
			}
		}
	}
}

pub fn (mut self Module) init() ! {
	self.build_factories()!

	for mut global_mod in self.globals {
		global_mod.internal_inject()!
	}
	self.internal_inject()!

	for mut global_mod in self.globals {
		global_mod.internal_init()!
	}
	self.internal_init()!
}

/*
Will return the list of factories for this module and the imports, but not for the Globals
*/
pub fn (self Module) get_factories() []Factory {
	mut factories_list := []Factory{}
	for factory in self.factories {
		factories_list << factory
	}

	for import_module in self.imports {
		for factory in import_module.factories {
			factories_list << factory
		}
	}
	return factories_list
}

pub fn (mut self Module) build_factories() ! {
	mut factories_list := []Factory{}

	for global_module in self.globals {
		for factory in global_module.get_factories() {
			factories_list << factory
		}
	}

	for factory in self.get_factories() {
		factories_list << factory
	}

	mut has_instantiated_factories := true
	for has_instantiated_factories && factories_list.len > 0 {
		has_instantiated_factories = false
		for mut factory in factories_list {
			if factory.can_instantiate() {
				println('Instantiating factory of ${factory.typ}')
				has_instantiated_factories = true
				factory.build()!
				factory.instantiated = true
			}
		}
		factories_list = factories_list.filter(!it.instantiated)
	}
	if factories_list.len > 0 {
		return error('Some factory cannot be initialized, avoid circular dependencies')
	}
}
