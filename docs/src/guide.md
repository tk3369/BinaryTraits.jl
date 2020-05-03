## Defining traits

### The @trait macro

You can define a new trait using the `@trait` macro.
The syntax is described below:

```julia
@trait <Trait> [as <Category>] [prefix <Can>,<Cannot>] [with <Trait1>,<Trait2>,...]
```

* A trait type `<Trait>Trait` will be automatically defined
* `<Can>` and `<Cannot>` are words that indicates whether a data type exhibits the trait.
* `<Trait1>`, `<Trait2>`, etc. are used to define composite traits.

The as-clause, prefix-clause, and with-clause are all optional.

### Specifying super-type for trait

The as-clause is used to specify the super-type of the trait type.
If the clause is missing, the super-type is defaulted to `Any`.
This may be useful when you want to group a set of traits under the
same hierarchy.  For example:

```@example guide
using BinaryTraits  # hide
abstract type Ability end
@trait Fly as Ability
@trait Swim as Ability
```

### Using custom prefixes

When you define a trait using verbs like *Fly* or *Swim* in the above, it makes sense to define
trait types with `Can` and `Cannot` prefixes.  But, what if you want to define a trait using a
noun or an adjective? In that case, you can define your trait with the prefix-clause.
For example:

```julia
@trait Iterable prefix Is,Not
```

In this case, the following types will be defined instead:
```
IsIterable
NotIterable
```

This should make your code a lot more readable.

### Making composite traits

Sometimes we really want to compose traits and use a single one directly
for dispatch.  In that case, we can just use the with-clause like this:

```@example guide
@trait FlySwim with Fly,Swim
```

This above syntax would define a new trait where it assumes the
sub-traits `Fly` and `Swim`.  Then, we can just apply the Holy Trait
pattern as usual:

```julia
spank(x) = spank(flyswimtrait(x), x)
spank(::CanFlySwim, x) = "Flying high and diving deep"
spank(::CannotFlySwim, x) = "Too Bad"
```

## Assigning traits to types

Once you define your favorite traits, you may assign any data type to any traits.
The syntax of the assignment is as follows:

```julia
@assign <DataType> with <Trait1>,<Trait2>,...
```

You can assign a data type with 1 or more traits in a single statement:

```julia
struct Crane end
@assign Crane with CanFly,CanSwim
```

When you assign traits to a data type, it will be equivalent to defining
these functions:

```julia
flytrait(::Crane) = CanFly()
swimtrait(::Crane) = CanSwim()
```

## Specifying interfaces

A useful feature of traits is to define formal interfaces.  Currently, Julia does not
come with any facility to specify interface contracts.  The users are expected to
look up interface definitions from documentations and make sure that they implement
those contracts per documentation.

This package provides additional machinery for users to formally define interfaces.
It also comes with a macro for verifying the validity of data
type implementations.

### Formal interface contracts

Once you have defined a trait, you may define a set of interface contracts that a
data type must implement in order to carry that trait.  These contracts are registered
in the BinaryTraits system using the `@implement` macro.
The syntax of `@implement` is as follows:

```julia
@implement <CanType> by <FunctionSignature>
```

The value of `<CanType>` is the positive side of a trait e.g. `CanFly`, `IsIterable`,
etc.  The `<FunctionSignature>` is basically a standard function signature.

The followings are all valid usages:

```@example guide
@implement CanFly by liftoff()
@implement CanFly by fly(direction::Float64, altitude::Float64)
@implement CanFly by speed()::Float64
```

!!! note
    When return type is not specified, it is default to `Any`.
    Return type is currently not validated so it could be used here
    just for documentation purpose.

!!! note
    As you will see below, the functions need to be defined with the
    an object to be the first argument.  It is excluded from the interface
    definition for convenience reasons.

### Implementing interface contracts

A data type that is assigned to a trait should implement all interface contracts.
From the previous section, we established three contracts for the `Fly` trait -
`liftoff`, `fly`, and `speed`. To satisfy those contracts, we must implement those functions.

So let's say we are defining a `Bird` type that exhibits `Fly` trait, we implement
the `liftoff` contract as shown below:

```@example guide
abstract type Animal end
struct Bird <: Animal end
@assign Bird with CanFly
liftoff(bird::Bird) = "Hoo hoo!"
nothing # hide
```

Note that I must include an object to be the first argument of the function.
In this case, I have chosen to pass a `Bird` object.

However, it would be more practical when you have multiple types that satisfy
the same trait.  So, Holy Trait comes to rescue:

```@example guide
liftoff(x::Animal) = liftoff(flytrait(x), x)
liftoff(::CanFly, x) = "Hi ho!"
liftoff(::CannotFly, x) = "Hi ho!"
nothing # hide
```

### Validating a type against its interfaces

The reason for spending so much effort in specifying interface contracts is
so that we have a high confidence about our code.  Julia is a dynamic system
and so generally speaking we do not have any static type checking in place.
BinaryTraits now gives you that capability.

The `@check` macro can be used to verify whether your data type has fully
implemented its assigned traits and respective interface contracts.  The usage
is embarrassingly simple.  You can just call the `@check` macro with the
data type:

```@repl guide
@check(Bird)
```

The `@check` macro returns an `InterfaceReview` object, which gives you the
validation result.  The warnings are generated so that it comes up in the log file.
The following text is the display for the `InterfaceReview` object.  It is designed
to clearly show you what has been implemented and what's not.

!!! note
    When you define composite traits, all contracts from the underlying traits must be
    implemented as well.  If you have a `FlySwim` trait, then all contracts specified
    for `CanFly` and `CanSwim` are required even though you have not added any new
    contracts for `CanFlySwim`.

!!! note
    One way to utilize the `@check` macro is to put that in your module's `__init__` function
    so that it is verified before the package is used.  Another option is to do that in your
    test suite and so it will be run every single time.

## Additional step for framework providers

BinaryTraits is designed to allow one module to define traits and interfaces and
have other modules implementing them.  For example, it should be possible for
[Tables.jl](https://github.com/JuliaData/Tables.jl) to define traits for
row tables and column tables and required interface functions, and have
all of its [integrations](https://github.com/JuliaData/Tables.jl/blob/master/INTEGRATIONS.md)
participate in the same traits system.

In order to facilitate interaction between modules, BinaryTraits requires the
framework provider (e.g. Tables.jl in the example above) to add the following
code in its `__init__` function:

```julia
function __init__()
    inittraits(@__MODULE__)
end
```

This additional steps allows all packages that utilize BinaryTraits to register
their traits and interface contracts at a central location.

## Summary

The ability to design software with traits and interfaces and the ability to verify
software for conformance to established interface contracts are highly desirable for
professional software development projects.
