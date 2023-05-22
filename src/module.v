module vest

import arrays {index_of_first}

pub struct Service {
	name string
	instance voidptr
}

pub struct Module {
mut:
	services map[string]Service = map[string]Service{}
}

const inject_key = 'inject:'

fn get_key(attrs []string)?string {
	first_inject_index := index_of_first(attrs,fn (idx int, attr string) bool{ return attr.starts_with(inject_key)})
	if first_inject_index>=0{
		attr := attrs[first_inject_index]
		name := attr[inject_key.len..]
		return name.trim(' ')
	}
	return none
}

pub fn (mut self Module) register[T]() !&T {
	mut new_service := &T{}
	inject_name := T.name

	$for field in T.fields {
		if field_inject_name := get_key(field.attrs) {
			service := self.get_service(field_inject_name) or { return error('Invalid injection name ${field_inject_name} for field ${field.name} in ${T.name}')}
			new_service.$(field.name)= unsafe {service.instance}
		}
	}

	if inject_name in self.services {
		return error('Name ${inject_name} has been already registered')
	}
	self.services[inject_name] = Service{
		name: T.name,
		instance: new_service
	}
	return new_service
}

fn (self &Module) get_service(name string) !Service {
	return self.services[name] or { return error('Service with name ${name} not available, see available: ${self.services.keys()}')}
}

pub fn (self &Module) get[T](name string) !&T {
	service := self.get_service(name)!
	if service.name == T.name {
		return unsafe{ &T(service.instance) }
	} else {
		return error('Type ${T.name} is not ${service.name}')
	}
}
