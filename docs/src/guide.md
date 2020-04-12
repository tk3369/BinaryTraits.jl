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
same "umbrella".  The following are valid syntaxes:

```@example guide
using BinaryTraits

abstract type Movement end

@trait Fly
@trait Dive as Movement
```

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

```@example guide
@trait Fly
@trait Swim
@trait FlySwim with Fly,Swim
```

Then, we can just dispatch as follows:

```@example guide
spank(x) = spank(flyswimtrait(x), x)
spank(::CanFlySwim, x) = "Flying high and diving deep"
spank(::CannotFlySwim, x) = "Too Bad"
```

### Assigning traits

Once you define your favorite traits, you may assign any data type to any traits.
The syntax of the assignment is as follows:

```julia
@assign <DataType> with <trait1>,<trait2>,...
```

You can assign a data type with 1 or more traits in a single statement:
```julia
struct Crane end
@assign Crane with Fly,Swim
```

## Interfaces

A useful feature of traits is to define formal interfaces.  Currently, Julia does not
come with any facility to specify functional interfaces.  The users are expected to
look up interface definitions from documentations.

This package provides additional machinery to formally define interfaces. It also
comes with an interface checker that can be used to verify the validity of data
type implementations.

### Defining interfaces

Once you have defined a trait, you may define a set of interface contracts that a
data type must implement when exhibiting the trait.  These contracts are registered
in the BinaryTraits system using the `@implement` macro.

The syntax of `@implement` is as follows:

```julia
@implement <CanType> by <FunctionSignature>
```

The value of `<CanType>` is the positive side of the trait e.g. `CanFly`, `IsIterable`,
etc.  The `<FunctionSignature>` is basically a standard function signature, without
the first argument for displatch.

The followings are all valid usages:

```@example guide
@implement CanFly by liftoff()
@implement CanFly by fly(direction::Float64, altitude::Float64)
@implement CanFly by speed()::Float64
```

When return type is not specified, it is default to `Any`.
*Note that return type is currently not validated so it could be used here
just for documentation purpose.*

### Implementing interfaces

A data type that is assigned to a trait should implement all interface contracts.
In the previous section, we established three contracts for the `Fly` trait.

To satisfy those contracts, we must implement the same functions with the
additional requirement that the first argument must accept an object of your
data type.

So let's say we are defining a `Bird` type that exhibits `Fly` trait, we would
do something like this:

```@example guide
abstract type Animal end
struct Bird <: Animal end
@assign Bird with Fly
liftoff(bird::Bird) = "Hoo hoo!"
```

However, it would be more practical when you have multiple types that satisfy
the trait.  Hence Holy Trait comes to rescue:

```@example guide
liftoff(x::Animal) = liftoff(flytrait(x), x)
liftoff(::CanFly, x) = "Hi ho!"
liftoff(::CannotFly, x) = "Hi ho!"
```

### Verifying interfaces

The reason for spending so much effort in specifying interface contracts is
so that we have a high confidence about our code.  Julia is a dynamic system
and so generally speaking we do not have any static type checking in place.
However, BinaryTraits now gives you that capability.

The `check` function can be used to verify whether your data type has fully
implemented its assigned traits and respective interface contracts.  The usage
is embarassingly simple.  You can just call the `check` function with the
data typ:

```@example guide
check(Bird)
```

The `check` function returns an `InterfaceReview` object, which gives you the
validation result.  Continuing with the same example above:

The warnings are generated so that it comes up in the log file.   The following text
is the display for the `InterfaceReview` object.  It is designed to clearly show you
what has been implemented and what's not.

!!! note
    One way to utilize the `check` function is to put that in your module's `__init__` function
    so that it is verified before the package is used.  Another option is to do that in your
    test suite and so it will be run every single time.

## Summary

The ability to design software with traits and interfaces and the ability to verify
software for conformance to established interface contracts are highly desirable for
professional software development projects.
