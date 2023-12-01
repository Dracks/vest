module vest

import v.reflection

struct Void{}

pub struct Service {
	typ    int      @[required]
	inject InjectCb @[required]
	name   string   @[required]
	// This will be a workarround as the reflection in V is not working correctly and is not unwrapping/wrapping
	// the type on assignation
	// TODO: https://github.com/vlang/v/issues/18256
	originalptr voidptr @[required]
mut:
	instance &Object = &Object(Void{}) @[required]
}

fn (mut self Service) init() ! {
	if mut self.instance is InitService {
		self.instance.on_init()!
	}
}

struct Factory {
	typ             int
	dependencies    []int
	can_instantiate fn () bool @[required]
	build           fn () !    @[required]
mut:
	instantiated bool
}

@[inline]
fn (self Module) is_registered(typ_idx int) bool {
	if typ_idx in self.services {
		return true
	}
	if self.factories.filter(it.typ == typ_idx).len > 0 {
		return true
	}
	return false
}

pub fn (mut self Module) register[T]() &T {
	mut new_service := &T{}
	typ_idx := typeof[T]().idx
	typ := reflection.get_type(typ_idx) or { panic('Type not found ${T.name}') }

	if self.is_registered(typ_idx) {
		panic('Type ${typ.name} has been already registered')
	}

	for alias in get_aliases[T]() {
		self.aliases[alias] = typ_idx
	}
	// Workarround to avoid a V bug
	// ToDo: remove when https://github.com/vlang/v/issues/18294 is fixed
	if false {
		self.inject_to_object[T](mut new_service) or { panic(err) }
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

pub fn (mut self Module) use_instance[T](data T, export bool) {
	instance := &data
	typ_idx := typeof[T]().idx

	typ := reflection.get_type(typ_idx) or { panic('Type not found ${T.name}') }

	if self.is_registered(typ_idx) {
		panic('Type ${typ.name} has been already registered')
	}

	self.services[typ_idx] = Service{
		name: T.name
		typ: typ_idx
		instance: instance
		originalptr: instance
		inject: fn () ! {}
	}

	if export {
		self.export[T]()
	}
}

pub fn (mut self Module) use_factory[F, T](factory fn (c F) T, export bool) {
	println('WARNING: Factories are in alpha stage, can have injection problems')
	typ_idx := typeof[T]().idx
	typ := reflection.get_type(typ_idx) or { panic('Type not found ${T.name}') }

	if self.is_registered(typ_idx) {
		panic('Type ${typ.name} has been already registered')
	}

	// Workarround to avoid a V bug
	// ToDo: remove when https://github.com/vlang/v/issues/18294 is fixed
	if false {
		self.inject_to_object[F](mut F{}) or { panic(err) }
	}
	mut dependencies := []int{}
	$for field in F.fields {
		dependencies << field.typ
	}
	/*
	mut dependencies_object := &F{}
	self.inject_to_object(mut dependencies_object) or { panic(err)}*/
	internal_export := export

	self.factories << &Factory{
		typ: typ_idx
		dependencies: dependencies
		// TODO this mut self is a problem, I need to avoid passing self here
		can_instantiate: fn [mut self, dependencies] () bool {
			for dep_id in dependencies {
				if !self.check_exist(dep_id, none) {
					return false
				}
			}
			return true
		}
		build: fn [mut self, factory, typ_idx, internal_export] [F, T]() ! {
			println('Building factory for ${T.name}')
			mut dependencies_object := &F{}
			self.inject_to_object(mut dependencies_object)!
			// self.use_instance(factory(dependencies_object), internal_export)
			original_instance := factory(dependencies_object)
			instance := &original_instance
			self.services[typ_idx] = Service{
				name: T.name
				typ: typ_idx
				instance: instance
				originalptr: instance
				inject: fn () ! {}
			}

			if internal_export {
				self.export[T]()
			}
		}
	}
}
