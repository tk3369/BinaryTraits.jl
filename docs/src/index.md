Every motivation starts with an example.  In this page, we cover the following tasks:

1. Defining traits
2. Assigning data types with traits
3. Specifying an interface for traits
4. Checking if a data type fully implements all contracts from its traits
5. Applying Holy Traits pattern

# Example: tickling a duck and a dog

Suppose that we are modeling the ability of animals.  So we can define traits as follows:

```@example ex
abstract type Ability end
@trait Swim as Ability
@trait Fly as Ability
nothing # hide
```

Consider the following animal types. We can assign them traits quite easily:

```@example ex
struct Dog end
struct Duck end
@assign Dog with Swim
@assign Duck with Swim,Fly
nothing # hide
```

Next, how do you dispatch by traits?  You just follow the Holy Trait pattern:

```@example ex
tickle(x) = tickle(flytrait(x), swimtrait(x), x)
tickle(::CanFly, ::CanSwim, x) = "Flying high and diving deep"
tickle(::CanFly, ::CannotSwim, x) = "Flying away"
tickle(::Ability, ::Ability, x) = "Stuck laughing"
nothing # hide
```

*Voila!*

```@example ex
tickle(Dog())   # "Stuck laughing"
tickle(Duck())  # "Flying high and diving deep"
nothing # hide
```

## Working with interfaces

What if we want to enforce an interface? e.g. animals that can fly must
implement a `fly` method.  We can define that interface as follows:

```@example ex
@implement CanFly by fly(direction::Float64, altitude::Float64)::Nothing
```

Then, to make sure that our implementation is correct, we can use the `check`
function as shown below:

```@repl ex
check(Duck)
```

Now, let's implement the method and check again:

```@repl
fly(duck::Duck, direction::Float64, altitude::Float64) = "Having fun!"
check(Duck)
```

## Applying Holy Traits

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
