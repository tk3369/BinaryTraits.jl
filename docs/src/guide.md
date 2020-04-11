# User Guide

## Traits

### The @trait macro

The syntax of `@trait` macro is as follows:

```julia
@trait T [as <category>] [prefix <positive>,<negative>] [with <trait1>,<trait2>,...]
```

* `<positive>` and `<negative>` are words that indicates whether a data type exhibits the trait.
* `<trait1>`, `<trait2>`, etc. are used to define composite traits.

### Using custom super-type

The as-clause is used to specify the super-type of the trait type.
If the clause is missing, the super-type is defaulted to `Any`.

This may be useful when you want to group a set of traits under the
same "umbrella".

### Specifying custom Prefixes

When you define a trait using verbs like *Fly* or *Swim* in the above, it makes sense to define
trait types with `Can` and `Cannot` prefixes.  But, what if you want to define a trait using a
noun or an adjective?

In that case, you can define your trait with the `prefix` clause.  For example:

```julia
@trait Iterable prefix Is,Not
```

In that case, the following types will be defined instead:
```
IsIterable
NotIterable
```

This should make your code a lot more readable.

### Making composite traits

Sometimes we really want to compose traits and use it directly for dispatch.  In that case, we just
need to use the `with` clause:

```julia
@trait Fly
@trait Swim
@trait FlySwim with Fly,Swim
```

Then, we can just dispatch as follows:

```julia
spank(x) = spank(flyswimtrait(x), x)
spank(::CanFlySwim, x) = "Flying high and diving deep"
spank(::CannotFlySwim, x) = "Too Bad"
```

### Assigning traits

Once you define your favorite traits, you may assign any data type to these traits.

For example:
```
@trait Wheels prefix Has,No
@trait Engine prefix Has,No

struct Car end
@assign Car with Engine,Wheels
```

## Interfaces

A useful feature of traits is to define formal interfaces.  Currently, Julia does not
come with any facility to specify functional interfaces.  The users are expected to
look up interface definitions from documentations.

This package provides additional machinery to formally define interfaces. It also
comes with an interface checker that can be used to verify the validity of data
type implementations.

### Defining interfaces

TBD

### Implementing interfaces

TBD

### Verifying interfaces

TBD
