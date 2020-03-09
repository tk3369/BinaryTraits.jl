# BinaryTraits.jl

BinaryTraits is yet another traits library for Julia.  This package focuses on usability - traits should be simple to understand and easy to use.  For that reason, it is designed to be an "*opinionated* library, and it follow certain conventions.

The underlying mechanism is just [Holy Traits](https://ahsmart.com/pub/holy-traits-design-patterns-and-best-practice-book.html).  If you think about Holy Traits as the powerful manual transmission, then BinaryTraits is like automatic transmission.  The machinery is the same but it is a lot more pleasant to use for casual users.

A design consideration is to support only binary traits.  You either can do something or you cannot.  Putting this restriction in place makes everything easier (at least for me 😉). Traits must be explicitly assigned to data types.

This package supports the concept of composite traits.  A composite traits is defined as a data type that exhibits all of the underlying traits.

## Example: tickling a duck and a dog

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
@assign Duck with Swim, Fly
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

## Choosing your own prefix for trait types

When you define a trait using verbs like "Fly" or "Swim" in the above, it makes sense to define trait types with `Can` and `Cannot` prefixes.  But, what if you want to define a trait using a noun or adjective?

In that case, you can define your trait with the `prefix` clause:

```julia
abstract type Collection end
@trait Iterable as Collection prefix Is,Not
```

In that case, the following types will be defined instead:
```
IsIterable
NotIterable
```

This should make your code a lot more readable.

## Making composite traits

Sometimes we really want to compose traits and use it directly for dispatch.  In that case, we just need to use the `with` clause:

```julia
@trait FlySwim as Ability prefix Can,Cannot with Fly,Swim
```

Then, we can just dispatch as follows:

```julia
spank(x) = spank(flyswimtrait(x), x)
spank(::CanFlySwim, x) = "Flying high and diving deep"
spank(::CannotFlySwim, x) = "Too Bad"
```

Magically, since a duck can fly and swim, it can be dispatched as such:

```julia
spank(Duck())   # "Flying high and diving deep"
spank(Dog())    # "Too Bad"
```

## How does it work?

The underlying machinery is extremely simple.  They can be found conveniently in the doc strings for the `@trait` and `@assign` macros as well.

Using the above example, when you define a `Fly` trait using `@trait` macro, it literally expands to the following code:

```julia
abstract type FlyTrait <: Ability end
struct CanFly <: FlyTrait end
struct CannotFly <: FlyTrait end
flytrait(x) = CannotFly()
```

As you can see, our *opinion* is to define a new abstract type called  `FlyTrait`.  Likewise, we define `CanFly` and `CannotFly` subtypes.  Finally, we define a default trait function `flytrait` that just returns an instance of `CannotFly`.  Hence, all data types are automatically disqualified from the trait by default.

Now, when you do `@assign Duck with Fly,Swim`, it is just translated to:

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
