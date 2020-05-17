The project home page is located at
[https://github.com/tk3369/BinaryTraits.jl](https://github.com/tk3369/BinaryTraits.jl).

Every motivation starts with an example.  In this page, we cover the following tasks:

1. Defining traits
2. Assigning data types with traits
3. Specifying an interface for traits
4. Checking if a data type fully implements all contracts from its traits
5. Applying Holy Traits pattern

## Example: tickling a duck and a dog

Suppose that we are modeling the ability of animals.  So we can define traits as follows:

```julia
using BinaryTraits
abstract type Ability end
@trait Swim as Ability
@trait Fly as Ability
```

Consider the following animal types. We can assign them traits quite easily:

```julia
using BinaryTraits.Prefix: Can, Cannot       # use custom trait prefixes

struct Dog end
struct Duck end
@assign Dog with Can{Swim}
@assign Duck with Can{Swim},Can{Fly}
```

Next, how do you dispatch by traits?  Just follow the Holy Trait pattern:

```julia
tickle(x::T) where T = tickle(trait(Fly, T), trait(Swim, T), x)
tickle(::Can{Fly}, ::Can{Swim}, x) = "Flying high and diving deep"
tickle(::Can{Fly}, ::Cannot{Swim}, x) = "Flying away"
tickle(::BinaryTrait{Fly}, ::BinaryTrait{Swim}, x) = "Stuck laughing"
```

*Voila!*

```julia
julia> tickle(Dog())
"Stuck laughing"

julia> tickle(Duck())
"Flying high and diving deep"
```

## Working with interfaces

What if we want to enforce an interface? e.g. animals that can fly must
implement a `fly` method.  We can define that interface as follows:

```julia
@implement Can{Fly} by fly(_, direction::Float64, altitude::Float64)
```

The underscore character is used to indicate how an object should be passed
to the `fly` function.

Then, to make sure that our implementation is correct, we can use the `@check`
macro as shown below:

```julia
julia> @check(Duck)
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
❌ Duck is missing these implementations:
1. BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
```

Now, let's implement the method and check again:

```julia
julia> fly(duck::Duck, direction::Float64, altitude::Float64) = "Having fun!"

julia> @check(Duck)
✅ Duck has implemented:
1. BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
```

## Applying Holy Traits

If we would just implement interface contracts directly on concrete types then it can
be too specific for what it is worth.  If we have 100 flying animals, we shouldn't need to define
100 interface methods for the 100 concrete types.

That's how Holy Traits pattern kicks in.  Rather than implementing the `fly` method
for `Duck` as shown in the previous section, we could have implemented the following
functions instead:

```julia
fly(x::T, direction::Float64, altitude::Float64) where T = fly(trait(Fly, T), x, direction, altitude)
fly(::Can{Fly}, x, direction::Float64, altitude::Float64) = "Having fun!"
fly(::Cannot{Fly}, x, direction::Float64, altitude::Float64) = "Too bad..."
```

The first function determines whether the object exhibits `Can{Fly}` or `Cannot{Fly}` trait
and dispatch to the proper function. We did not specify the type of the `x` argument
but in reality if we are dealing with the animal kingdom only then we can define an
abstract type `Animal` and qualify that in there where-clause as in `where {T <: Animal>}`.
