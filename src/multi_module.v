module vest

fn (mut self Module) import_module(mut mod &Module){
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