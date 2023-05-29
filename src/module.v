module vest

import arrays { index_of_first }
import v.reflection

const (
	inject_key = 'inject:'
	provide_key = 'provide='
)

type InjectCb = fn () !

interface Object {}

pub interface InitService {
mut:
	on_init() !
}

pub interface DestroyService {
	on_destroy()!
}


pub struct Service {
	typ      int      [required]
	inject   InjectCb [required]
	name	string	[required]
// This will be a workarround as the reflection in V is not working correctly and is not unwrapping/wrapping 
// the type on assignation
// TODO: https://github.com/vlang/v/issues/18256
	originalptr voidptr [required]
mut:
	instance &Object  [required]
}

fn (mut self Service) init() ! {
	if mut self.instance is InitService {
		self.instance.on_init()!
	}
}

pub struct Module {
mut:
	aliases  map[string]int  = map[string]int{}
	services map[int]Service = map[int]Service{}
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
		return  self.get_service_by_name(field_inject_name) or {
			return error('Invalid injection name ${field_inject_name} for field ${field.name} in ${ t_name }')
		}
	} else if 'inject' in field.attrs {
		return self.get_service(field.typ) or {
			return error('Invalid injection type for field ${field.name} in ${t_name}')
		}
	}
	return false
}

pub fn (mut self Module) register[T]() &T {
	mut new_service := &T{}
	typ_idx := typeof[T]().idx
	typ := reflection.get_type(typ_idx) or {panic('Type not found ${T.name}')}

	if typ_idx in self.services {
		panic('Type ${typ.name} has been already registered')
	}

	for alias in get_aliases[T]() {
		self.aliases[alias] = typ_idx
	}
	self.services[typ_idx] = Service{
		name: T.name
		typ: typ_idx
		instance: new_service
		originalptr: new_service
		inject: fn [mut self, mut new_service] [T]() ! {
			$for field in T.fields {
				$if field.typ !is string {
					mut service := self.get_service_from_field(field,T.name)! 
					if mut service is Service {
						if service.typ != field.typ || field.indirections==0{
							return error("Type of property '${field.name}' in '${T.name}' must be ${service.name} as Reference")
						}
						unsafe {
						new_service.$(field.name) =  service.originalptr 
						}
					}
				}
			}
		}
	}
	return new_service
}

pub fn (self &Module) inject()! {
	for typ in self.services.keys() {
		self.services[typ].inject()!
	}
}

pub fn (mut self Module) init()! {
	for typ in self.services.keys() {
		self.services[typ].init()!
	}
}

fn (mut self Module) get_service(service_idx int) !Service {
	return self.services[service_idx] or {
		service_info := reflection.get_type(service_idx) or {
			return err
		}
		return error('Service with name ${service_info.name} not available, see available: ${self.services.keys()}')
	}
}


fn (mut self Module) get_service_by_name(name string) !Service {
	service_idx := self.aliases[name] or {return error('Service with name ${name} not available, see available: ${self.aliases.keys()}')}
	return self.get_service(service_idx)
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
