The underlying machinery is extremely simple. When you define a traits like `@trait Fly as Ability`, it literally expands to the following code:

```julia
abstract type FlyTrait <: Ability end
struct CanFly <: FlyTrait end
struct CannotFly <: FlyTrait end
flytrait(x) = CannotFly()
```

As you can see, our *opinion* is to define a new abstract type called  `FlyTrait`.  Likewise, we define `CanFly` and `CannotFly` subtypes.  Finally, we define a default trait function `flytrait` that just returns an instance of `CannotFly`.  Hence, all data types are automatically defined from the trait by default.

Now, when you do `@assign Duck with CanFly,CanSwim`, it is just translated to:

```julia
flytrait(::Duck) = CanFly()
swimtrait(::Duck) = CanSwim()
```

Making composite traits is slightly more interesting.  It creates a new trait by combining multiple traits together.  Having a composite trait is defined as one that exhibits *all* of the underlying traits.  Hence, `@trait FlySwim as Ability with Fly,Swim` would be translated to the following:

```julia
abstract type FlySwimTrait <: Ability end
struct CanFlySwim <: FlySwimTrait end
struct CannotFlySwim <: FlySwimTrait end

function flyswimtrait(x)
    if flytrait(x) === CanFly() && swimtrait(x) === CanSwim()
        CanFlySwim()
    else
        CannotFlySwim()
    end
end
```
