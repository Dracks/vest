module vest

pub fn (mut self Module) inject_to_object[T](mut new_service T) ! {
	$for field in T.fields {
		mut service := self.get_service_from_field(field, T.name)!
		if mut service is Service {
			$if field.indirections > 0 {
				if service.typ != field.typ {
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

fn (mut self Module) internal_inject() ! {
	if !self.is_injected {
		self.is_injected = true

		for mut mod in self.imports {
			mod.internal_inject()!
		}

		for typ in self.services.keys() {
			if mut service := self.services[typ]{
				service.inject()!
			}
		}
	}
}
