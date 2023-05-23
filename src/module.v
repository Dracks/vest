module vest

import arrays { index_of_first }
import v.reflection

type InjectCb = fn () !

pub interface InitService {
	on_init() !
}

/*
pub interface DestroyService {
	on_destroy()!
}
*/

pub struct Service {
	typ      int      [required]
	instance voidptr  [required]
	inject   InjectCb [required]
}

fn (self &Service) init() ! {
	if type_info := reflection.get_type(self.typ) {
		println(type_info)
		on_init_idx := index_of_first(type_info.sym.methods, fn (_idx int, method reflection.Function) bool {
			return method.name == 'on_init' && method.args.len == 1
		})
		if on_init_idx != -1 {
			service := unsafe { InitService(self.instance) }
			println('on_init')
			println(service)
			println(self.instance)
			service.on_init()!
			println('Something really bad!')
		}
	}
}

pub struct Module {
mut:
	aliases  map[string]int  = map[string]int{}
	services map[int]Service = map[int]Service{}
}

const (
	inject_key = 'inject:'
	provide_key = 'provide='
)

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
		//name: T.name
		typ: typ_idx
		instance: new_service
		inject: fn [self, mut new_service] [T]() ! {
			$for field in T.fields {
				if field_inject_name := get_key(field.attrs) {
					service := self.get_service_by_name(field_inject_name) or {
						return error('Invalid injection name ${field_inject_name} for field ${field.name} in ${T.name}')
					}
					new_service.$(field.name) = unsafe { service.instance }
				} else if 'inject' in field.attrs {
					service := self.get_service(field.typ) or {
						return error('Invalid injection type for field ${field.name} in ${T.name}')
					}
					new_service.$(field.name) = unsafe { service.instance }
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

pub fn (self &Module) init()! {
	for typ in self.services.keys() {
		println(typ)
		println('init')
		self.services[typ].init()!
	}
}

fn (self &Module) get_service(service_idx int) !Service {
	return self.services[service_idx] or {
		service_info := reflection.get_type(service_idx) or {
			return err
		}
		return error('Service with name ${service_info.name} not available, see available: ${self.services.keys()}')
	}
}


fn (self &Module) get_service_by_name(name string) !Service {
	service_idx := self.aliases[name] or {return error('Service with name ${name} not available, see available: ${self.aliases.keys()}')}
	return self.get_service(service_idx)
}

pub fn (self &Module) get[T](name ?string) !&T {
	lookup_name := name or { T.name[1..] }
	service := self.get_service_by_name(lookup_name)!
	if service.typ == typeof[T]().idx {
		return unsafe { &T(service.instance) }
	} else {
		return error('Type ${T.name} is not valid')
	}
}
