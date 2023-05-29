# Vest
Vest is a dependency injection library based on angular/nestjs, 
in which you have modules and they autoinject in the providers of the modules, 
and the providers can be exported to be reused in other modules

## Usage

```vlang
struct ServiceToBeInjected {
    // Whatever you wish here
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

// Inject dependencies
mod.inject()!

// Initialize objects calling to on_init method
mod.init()!


```
