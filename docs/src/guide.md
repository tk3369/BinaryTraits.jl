## Defining traits

### The @trait macro

You can define a new trait using the `@trait` macro.
The syntax is described below:

```julia
@trait <TraitName> [as <SuperType>] [prefix <Can>,<Cannot>] [with <Trait1>,<Trait2>,...]
```

* `<TraitName>`: an abstract type is defined with the same name
* `<SuperType>`: optional super-type of the trait's abstract type
* `<Can>` and `<Cannot>`: words that indicate whether a data type exhibits the trait or not
* `<Trait1>`, `<Trait2>`, etc. can be specified to define composite traits.

The as-clause, prefix-clause, and with-clause are all optional.

### Specifying super-type for trait

The as-clause is used to specify the super-type of the trait type.
If the clause is missing, the super-type is defaulted to `Any`.
This may be useful when you want to group a set of traits under the
same hierarchy.  For example:

```julia
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

Alternative, there are predefined trait prefixes from the BinaryTraits.Prefix sub-module.
They are listed below for your convenience:

Trait prefixes as aliases of `Positive`:
- `Can`
- `Has`
- `Is`

Traits prefixes as aliases of `Negative`:
- `Cannot`
- `No`
- `Not`
- `IsNot`

You may just import the pre-defined prefixes as you see fit.  The prefixes are

### Making composite traits

Sometimes we really want to compose traits and use a single one directly
for dispatch.  In that case, we can just use the with-clause like this:

```julia
@trait FlySwim with Can{Fly}, Can{Swim}
```

This above syntax would define a new trait where it assumes the
positive side of the traits `Fly` and `Swim`.

A less common usage is to create trait types can is composed of both
positive and negative traits.  Hence, you can define something like this:

```julia
@trait SeaCreature with Can{Swim},Cannot{Fly}
```

## Assigning traits to types

Once you define your favorite traits, you may assign any data type to any traits.
The syntax of the assignment is as follows:

```julia
@assign <Type> with <Trait1>,<Trait2>,...
```

You can assign a data type with 1 or more positive (or negative) trait types
in a single statement:

```julia
struct Crane end
@assign Crane with Can{Fly},Can{Swim}
```

Doing such assignment allows us to enforce interface contracts as you will see
in the next section.

## Specifying interfaces

A ver useful feature of BinaryTraits is to define formal interfaces.  Currently, Julia does not
come with any facility to specify interface contracts.  The users are expected to
look up interface definitions from documentations and make sure that they implement
those contracts per documentation accordingly.

This package provides additional machinery for users to formally define interfaces.
It also comes with a macro for verifying the validity of data
type implementations.

### Formal interface contracts

Once you have defined a trait, you may define a set of interface contracts that a
data type must implement in order to exhibit that trait.  These contracts are registered
in the BinaryTraits system using the `@implement` macro.
The syntax of `@implement` is as follows:

```julia
@implement Positive{<Trait>} by <FunctionSignature>
@implement Negative{<Trait>} by <FunctionSignature>
```

In general, the first form is what one normally use.  You are basically telling the
system that a data type that exhibits the `Trait` must implement a function that is
given the the `<FunctionSignature>`.

The words `Positive` and `Negative` are the standard parametric types
for specifying the direction of the trait.  Alternatively, you may use the custom prefixes
that you defined from the `@trait` macro.

Here are some examples:

```julia
@implement Can{Fly} by liftoff(_)
@implement Can{Fly} by fly(_, direction::Float64, altitude::Float64)
@implement Can{Fly} by speed(_)::Float64
```

The underscore `_` is a special syntax where you can indicate which positional
argument you want to pass an object to the function.  The object is expected
to have a type that is assigned to the `Fly` trait.

When return type is not specified, it is default to `Any`.
Return type is currently not validated so it could be used here
just for documentation purpose.

!!! note
    The underscore may be placed at any argument position although it is
    quite common to leave it as the first argument.

!!! note
    If you have multiple underscores, then the semantic is such that they
    are all of the same type.  For example, two ducks may exhibits a
    `Playful` trait and a `play(_, _)` interface expects an implementation
    of `play(::Duck, ::Duck)`.

Although not as common, it is also possible to use the negative part
of the trait e.g. `Cannot{Fly}` for interface specification.

### Implementing interface contracts

A data type that is assigned to a trait should implement all interface contracts.
From the previous section, we established three contracts for the `Fly` trait -
`liftoff`, `fly`, and `speed`. To satisfy those contracts, we must implement those functions.

For example, let's say we are defining a `Bird` type that exhibits `Fly` trait,
we can implement the following contracts:

```julia
abstract type Animal end
struct Bird <: Animal end
@assign Bird with Can{Fly}

# implmementation of Can{Fly} contracts
liftoff(bird::Bird) = "Hoo hoo!"
fly(bird::Bird, direction::Float64, altitude::Float64) = "Getting there!"
speed(bird::Bird) = 10.0
```

Here, we implement the contracts directly with the specific concrete type.
What if you have multiple types that satisfy the same trait.
Holy Trait comes to rescue:

```julia
liftoff(x::T) where {T <: Animal} = liftoff(trait(Fly, T), x)
liftoff(::Can{Fly}, x) = "Hi ho!"
liftoff(::Cannot{Fly}, x) = "baaa!"
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

```julia
julia> @check(Bird)
✅ Bird has no interface contract requirements.
```

The `@check` macro returns an `InterfaceReview` object, which gives you the
validation result.  The warnings are generated so that it comes up in the log file.
The string representation of the `InterfaceReview` object is designed
to clearly show you what has been implemented and what's not.

!!! note
    When you define composite traits, all contracts from the underlying traits must be
    implemented as well.  If you have a `FlySwim` trait, then all contracts specified
    for `Can{Fly}` and `Can{Swim}` are required even though you have not added any new
    contracts for `Can{FlySwim}`.

!!! note
    One way to utilize the `@check` macro is to put that in your module's `__init__` function
    so that it is verified before the package is used.  Another option is to do that in your
    test suite and so it will be run every single time.

## Notes for framework providers

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
    init_traits(@__MODULE__)
end
```

This additional steps allows all packages that utilize BinaryTraits to register
their traits and interface contracts at a central location.

## Summary

BinaryTraits is designed to fill the language gap as related to the lack of a
formal traits and interface system.

The ability to design software with traits and interfaces and the ability to verify
software for conformance to established interface contracts are highly desirable for
professional software development projects.
