# BinaryTraits

BinaryTraits is yet another traits library for Julia.  This package focuses on usability - traits should be simple to understand and easy to use.

The underlying mechanism is just [Holy Traits](https://ahsmart.com/pub/holy-traits-design-patterns-and-best-practice-book.html).  If you think about Holy Traits as the powerful manual transmission, then BinaryTraits is like automatic transmission.  The machinery is the same but it is a lot pleasant to use for casual users.

A design consideration is to support only binary traits.  You either can do something or you cannot.  Putting this restriction in place makes everything easier. Another important feature is the support of composite traits.

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

Then use multiple dispatch using Holy Traits pattern as follows:

```julia
tickle(x) = tickle(flytrait(x), swimtrait(x), x)
tickle(::CanFly, ::CanSwim, x) = "Flying high and diving deep"
tickle(::CanFly, ::CannotSwim, x) = "Flying away"
tickle(::Ability, ::Ability, x) = "Stuck laughing"
```

So it must work as such:
```
tickle(Dog()) == "Stuck laughing"
tickle(Duck()) == "Flying high and diving deep"
```

## Composing traits

Sometimes we really want to compose traits and use it directly for dispatch.  The `@traitgroup` macro serves that purpose.

```julia
@traitgroup FlySwim with Fly,Swim
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

## Todo's

- Perhaps using `Can` and `Cannot` is too opinionated.  Shall we let the user choose between `Can/Cannot`, `Is/Not`, `Has/No`? i.e.

```
IsTable/NotTable
IsIteratble/NotIterable
HasWings/NoWings
```
