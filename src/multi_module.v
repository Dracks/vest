module vest

fn (self Module) get_all_childs(mut childs []&Module) {
	for glob in self.globals {
		if glob !in childs {
			childs << glob
			glob.get_all_childs(mut childs)
		}
	}

	for mod in self.imports {
		if mod !in childs {
			childs << mod
			mod.get_all_childs(mut childs)
		}
	}
}

pub fn (mut self Module) import_module(mut mod Module) {
	if mod.global {
		self.globals << mod
	} else {
		self.imports << mod
	}

	if self.globals != mod.globals {
		for global_mod in mod.globals {
			if global_mod !in self.globals {
				self.globals << global_mod
			}
		}
		mut childs := []&Module{}
		childs << mod
		mod.get_all_childs(mut childs)
		for mut child_mod in childs {
			child_mod.globals = self.globals
		}
	}
}

fn (mut self Module) export[T]() {
	self.exported_services << typeof[T]().idx
}

pub fn (mut self Module) register_and_export[T]() &T {
	new_service := self.register[T]()

	self.export[T]()

	return new_service
}
