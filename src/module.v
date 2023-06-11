module vest

import arrays { index_of_first }
import v.reflection

const (
	inject_key = 'inject:'
	provide_key = 'provide='
)

type InjectCb = fn () !

pub interface Object {}

pub interface InitService {
mut:
	on_init() !
}

pub interface DestroyService {
	on_destroy() !
}

pub struct Service {
	typ    int      [required]
	inject InjectCb [required]
	name   string   [required]
	// This will be a workarround as the reflection in V is not working correctly and is not unwrapping/wrapping
	// the type on assignation
	// TODO: https://github.com/vlang/v/issues/18256
	originalptr voidptr [required]
mut:
	instance &Object [required]
}

fn (mut self Service) init() ! {
	if mut self.instance is InitService {
		self.instance.on_init()!
	}
}

pub struct Module {
	global bool
mut:
// ToDo, this will be better done with some kind of build factory
	is_injected bool
	is_init bool
	aliases  map[string]int  = map[string]int{}
	services map[int]Service = map[int]Service{}
	exported_services []int = []int{}
	imports []&Module = []&Module{}
	globals []&Module = []&Module{}
}

fn get_key(attrs []string) ?string {
	first_inject_index := index_of_first(attrs, fn (idx int, attr string) bool {
		return attr.starts_with(inject_key)
	})
	if first_inject_index >= 0 {
		attr := attrs[first_inject_index]
		name := attr[inject_key.len..]
		return name.trim(' ')
	}
	return none
}

fn get_aliases[T]() []string {
	mut aliases_list := [T.name[1..]]
	if typ := reflection.get_type(typeof[T]().idx) {
		info := typ.sym.info
		if info is reflection.Struct {
			for attr in info.attrs.filter(fn (attr string) bool {
				return attr.starts_with(provide_key)
			}) {
				aliases_list << attr[provide_key.len..]
			}
		}
	}

	return aliases_list
}

type ServiceOrNone = Service | bool

fn (mut self Module) get_service_from_field(field FieldData, t_name string) !ServiceOrNone {
	if field_inject_name := get_key(field.attrs) {
		return self.get_service_by_name(field_inject_name) or {
			return error('Invalid injection name ${field_inject_name} for field ${field.name} in ${t_name}')
		}
	} else if 'inject' in field.attrs {
		return self.get_service(field.typ) or {
			return error('Invalid injection type for field ${field.name} in ${t_name}')
		}
	}
	return false
}


fn (mut self Module) internal_inject()! {
	if !self.is_injected {
		self.is_injected = true
		
		for mut mod in self.imports {
			mod.internal_inject()!
		}

		for typ in self.services.keys() {
			self.services[typ].inject()!
		}
	}
}

fn (mut self Module) internal_init()! {
	if !self.is_init {
		self.is_init = true
		
		for mut mod in self.imports{
			mod.internal_init()!
		}

		for typ in self.services.keys() {
			self.services[typ].init()!
		}
	}
}

fn (mut self Module) init()!{
	for mut global_mod in self.globals {
		global_mod.internal_inject()!
	}
	self.internal_inject()!

	for mut global_mod in self.globals {
		global_mod.internal_init()!
	}
	self.internal_init()!
}

fn (self &Module) internal_get_service(service_idx int, exported bool) ?Service {
	if exported && service_idx !in self.exported_services {
		return none
	}
	return self.services[service_idx] or {return none}
}

fn (mut self Module) get_service(service_idx int) !Service {
	mut retrieved_service := self.internal_get_service(service_idx, false)
	if service := retrieved_service{
		return service
	}

	for mod in self.imports {
		if service := mod.internal_get_service(service_idx, true) {
			return service
		}
	}
	
	for mod in self.globals {
		if service := mod.internal_get_service(service_idx, true) {
			return service
		}
	}
	
	service_info := reflection.get_type(service_idx) or {
		return err
	}
	return error('Service with name ${service_info.name} not available, see available: ${self.services.keys()}')
}

fn (self &Module) internal_get_service_by_name(name string, exported bool) ?Service {
	if service_idx := self.aliases[name] {
		return self.internal_get_service(service_idx, exported)
	}
	return none
}

fn (mut self Module) get_service_by_name(name string) !Service {
	mut retrieved_service := self.internal_get_service_by_name(name, false)
	if service := retrieved_service{
		return service
	}

	for mod in self.imports {
		if service := mod.internal_get_service_by_name(name, true) {
			return service
		}
	}
	
	for mod in self.globals {
		if service := mod.internal_get_service_by_name(name, true) {
			return service
		}
	}
	
	return error('Service with name ${name} not available, see available: ${self.aliases.keys()}')
}

pub fn (mut self Module) get[T](optional_name ?string) !&T {
	service := if lookup_name:=optional_name {
		self.get_service_by_name(lookup_name)!
	} else {
		self.get_service(typeof[T]().idx)!
	}
	if service.instance is T {
		mut service_instance := service.instance
		return service_instance
	} else {
		return error('Type ${T.name} is not valid')
	}
}
