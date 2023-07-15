module vest

pub fn (mut self Module) import_module(mut mod &Module){
	if mod.global {
		self.globals << mod
	} else {
		self.imports << mod
	}
	
	if self.globals != mod.globals {
		for global_mod in mod.globals{
			if global_mod !in self.globals {
				self.globals << global_mod
			}
		}
		mod.globals = self.globals
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


pub fn (mut self Module) use_instance[T](instance T, export bool) {
	typ_idx := typeof[T]().idx
	typ := reflection.get_type(typ_idx) or { panic('Type not found ${T.name}') }

	if typ_idx in self.services {
		panic('Type ${typ.name} has been already registered')
	}

	// Workarround to avoid a V bug
	// ToDo: remove when https://github.com/vlang/v/issues/18294 is fixed
	if false {
		self.inject_to_object[T](mut new_service) or {panic(err)}
	}

	self.services[typ_idx] = Service{
		name: T.name
		typ: typ_idx
		instance: instance
		originalptr: instance
		inject: fn ()!{}
	}

	if export {
		self.export[T]()
	}
}
/*
pub fn (mut self Module) use_factory[F,T](factory fn (c F) T, export bool) {
	typ_idx := typeof[T]().idx
	typ := reflection.get_type(typ_idx) or { panic('Type not found ${T.name}') }

	if typ_idx in self.services {
		panic('Type ${typ.name} has been already registered')
	}

	// Workarround to avoid a V bug
	// ToDo: remove when https://github.com/vlang/v/issues/18294 is fixed
	if false {
		self.inject_to_object[T](mut new_service) or {panic(err)}
	}

	self.services[typ_idx] = Service{
		name: T.name
		typ: typ_idx
		instance: instance
		originalptr: instance
		inject: fn ()!{}
	}

	if export {
		self.export[T]()
	}
}
*/