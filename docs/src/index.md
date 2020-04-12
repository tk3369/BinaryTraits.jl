Every motivation starts with an example.  In this page, we cover the following tasks:

1. Defining traits
2. Assigning data types with traits
3. Specifying an interface for traits
4. Checking if a data type fully implements all contracts from its traits
5. Applying Holy Traits pattern

# Example: tickling a duck and a dog

Suppose that we are modeling the ability of animals.  So we can define traits as follows:

```julia
abstract type Ability end
@trait Swim as Ability
@trait Fly as Ability
```

Consider the following animal types. We can assign them traits quite easily:

```julia
struct Dog end
struct Duck end

@assign Dog with Swim
@assign Duck with Swim,Fly
```

Next, how do you dispatch by traits?  You just follow the Holy Trait pattern:

```julia
tickle(x) = tickle(flytrait(x), swimtrait(x), x)
tickle(::CanFly, ::CanSwim, x) = "Flying high and diving deep"
tickle(::CanFly, ::CannotSwim, x) = "Flying away"
tickle(::Ability, ::Ability, x) = "Stuck laughing"
```

*Voila!*

```julia
tickle(Dog())   # "Stuck laughing"
tickle(Duck())  # "Flying high and diving deep"
```

## Working with interfaces

What if we want to enforce an interface? e.g. animals that can fly must
implement a `fly` method.  We can define that interface as follows:

```julia
@implement CanFly by fly(direction::Float64, altitude::Float64)::Nothing
```

Then, to make sure that our implementation is correct, we can use the `check`
function as shown below:

```julia
julia> check(Duck)
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ fly(::Duck, ::Float64, ::Float64)::Nothing
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:169
❌ Duck is missing these implementations:
1. FlyTrait: CanFly ⇢ fly(::<Type>, ::Float64, ::Float64)::Nothing
```

Now, let's implement the method and check again:

```julia
julia> fly(duck::Duck, direction::Float64, altitude::Float64) = "Having fun!"

julia> check(Duck)
✅ Duck has implemented:
1. FlyTrait: CanFly ⇢ fly(::<Type>, ::Float64, ::Float64)::Nothing
```

## Applying holy traits

If we would just implement interface contracts directly on concrete types then it can
be too specific for what it is worth.  If we have 100 flying animals, I shouldn't need to define
100 interface methods for the 100 concrete types.

That's how Holy Trais pattern kicks in.  Rather than implementing the `fly` method
for `Duck` as shown in the previous section, we could have implemented the following
functions instead:

```julia
fly(x, direction::Float64, altitude::Float64) = fly(flytrait(x), x, direction, altitude)
fly(::CanFly, x, direction::Float64, altitude::Float64) = "Having fun!"
fly(::CannotFly, x, direction::Float64, altitude::Float64) = "Too bad..."
```

The first function determines whether the object exhibits `CanFly` or `CannotFly` trait
and dispatch to the proper function. We did not specify the type of the `x` argument
but in reality if we are dealing with the animal kingdom only then we can define an
abstract type `Animal` and apply holy traits to all `Animal` objects only.
