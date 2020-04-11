# User Guide

## Using the @trait macro

The syntax of `@trait` macro is as follows:

```julia
@trait T [as <category>] [prefix <positive>,<negative>] [with <trait1>,<trait2>,...]
```

* `<positive>` and `<negative>` are words that indicates whether a data type exhibits the trait.
* `<trait1>`, `<trait2>`, etc. are used to define composite traits.

### Choosing your own super-type of the trait type

The as-clause is used to specify the super-type of the trait type.
If the clause is missing, the super-type is defaulted to `Any`.

### Choosing your own prefix for trait types

When you define a trait using verbs like *Fly* or *Swim* in the above, it makes sense to define trait types with `Can` and `Cannot` prefixes.  But, what if you want to define a trait using a noun or an adjective?

In that case, you can define your trait with the `prefix` clause.  For example:

```julia
@trait Iterable prefix Is,Not
```

In that case, the following types will be defined instead:
```
IsIterable
NotIterable
```

This should make your code a lot more readable.

### Making composite traits

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

## Assigning traits to your data types

Once you define your favorite traits, you may assign any data type to these traits.

For example:
```
@trait Wheels prefix Has,No
@trait Engine prefix Has,No

struct Car end
@assign Car with Engine,Wheels
```

## How does it work?

The underlying machinery is extremely simple. When you define a traits like `@trait Fly as Ability`, it literally expands to the following code:

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
