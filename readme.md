# Vest
Vest is a dependency injection library based on angular/nestjs, 
in which you have modules and they autoinject in the providers of the modules, 
and the providers can be exported to be reused in other modules

## Usage

```vlang
import Dracks.vest {Module, InitService}

struct ServiceToBeInjected {
    // Whatever you wish here
}

// This method is not really needed, but it's a good way to ensure you implemented the on_init correctly
fn (self ServiceToBeInjected) to_init_service() InitService {
    return self
}

fn (mut self ServiceToBeInjected) on_init()! {
    println("Initializing this object")
}

struct StructThatHasInjectedFields {
    service &ServiceToBeInjected [inject]
}


# Create a new module
mut mod := Module{}

mod.register[ServiceToBeInjected]()
mod.register[StructThatHasInjectedFields]()

// Will inject dependencies and call all on_init methods
mod.init()!
```

### Submodules

You can create submodules to pack your services together. (Currently all services are exported), the usage can be something like: 
```vlang
// Using the same structs than before

mut submod := Module{}

submod.register[ServiceToBeInjected]()

mut mod := Module{}
mod.import_module(mut submod)

// Will inject dependencies and call all on_init methods
mod.init()!
```

Also you can set a module as global creating it like `Module{global: true}`, once this is imported, the services of this module will be available accross all modules. **Only to be used with specific cases, but should not be used normally**
