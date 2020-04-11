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

Then, to make sure that our implementation is correct, we can use the `@check`
macro as shown below:

```julia
julia> @check Duck
InterfaceReview(Duck) missing the following implementations:
1. CanFly ⇢ fly(::<Type>, ::Float64, ::Float64)::Nothing
```

Now, let's implement the method and check again:

```julia
julia> fly(duck::Duck, direction::Float64, altitude::Float64) = "Having fun!"

julia> @check Duck
InterfaceReview(Duck) has fully implemented these contracts:
1. CanFly ⇢ fly(::<Type>, ::Float64, ::Float64)::Nothing
```

## Applying holy traits

If we would just implement interface contracts directly then it can be too specific
for what it is worth.  If we have 100 flying animals, I shouldn't need to define
100 interface methods for the 100 concrete types.

That's how Holy Trais pattern kicks in.  Rather than implementing the `fly` method
as shown in the previous section, we could have implemented the following two
functions instead:

```julia
fly(::CanFly, x, direction::Float64, altitude::Float64) = "Having fun!"
fly(x, direction::Float64, altitude::Float64) = fly(flytrait(x), x, direction, altitude)
```

By definition, the `CanFly` trait should not be animal specific.  Hence generalizing
the implementation with the `CanFly` argument makes perfect sense.
