module vest

import v.reflection

pub fn (mut self Module) inject_to_object[T](mut new_service T) ! {
	$for field in T.fields {
		mut service := self.get_service_from_field(field, T.name)!
		if mut service is Service {
			$if field.indirections >0 {
				if service.typ != field.typ  {
					return error("Type of property '${field.name}' in '${T.name}' must be ${service.name} as Reference")
				}
				unsafe {
					new_service.$(field.name) = service.originalptr
				}
			} $else {
				return error("Type of property '${field.name}' in '${T.name}' must be ${service.name} as Reference")
			}
		}
	}
}

pub fn (mut self Module) register[T]() &T {
	mut new_service := &T{}
	typ_idx := typeof[T]().idx
	typ := reflection.get_type(typ_idx) or { panic('Type not found ${T.name}') }

	if typ_idx in self.services {
		panic('Type ${typ.name} has been already registered')
	}

	for alias in get_aliases[T]() {
		self.aliases[alias] = typ_idx
	}
	// Workarround to avoid a V bug
	// ToDo: remove when https://github.com/vlang/v/issues/18294 is fixed
	if false {
		self.inject_to_object[T](mut new_service) or {panic(err)}
	}
	self.services[typ_idx] = Service{
		name: T.name
		typ: typ_idx
		instance: new_service
		originalptr: new_service
		inject: fn [mut self, mut new_service] [T]() ! {
			self.inject_to_object[T](mut new_service)!
		}
	}
	return new_service
}
