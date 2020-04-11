# Example: tickling a duck and a dog

Suppose that we are modeling the ability of animals.  So we can define traits as follows:

```julia
abstract type Ability end
@trait Swim as Ability
@trait Fly as Ability
```

Consider the following animal types:

```julia
struct Dog end
struct Duck end
```

We may want to assign them traits:

```julia
@assign Dog with Swim
@assign Duck with Swim,Fly
```

Then, you can just do multiple dispatch as usual:

```julia
tickle(x) = tickle(flytrait(x), swimtrait(x), x)
tickle(::CanFly, ::CanSwim, x) = "Flying high and diving deep"
tickle(::CanFly, ::CannotSwim, x) = "Flying away"
tickle(::Ability, ::Ability, x) = "Stuck laughing"
```

So it just works:

```julia
tickle(Dog())   # "Stuck laughing"
tickle(Duck())  # "Flying high and diving deep"
```
