## Basic machinery

The machinery is extremely simple. When you define a traits like `@trait Fly as Ability`, it literally expands to the following code:

```julia
abstract type FlyTrait <: Ability end
struct CanFly <: FlyTrait end
struct CannotFly <: FlyTrait end
flytrait(x) = CannotFly()
```

As you can see, a new abstract type called  `FlyTrait` is automatically generated Likewise, we define `CanFly` and `CannotFly` subtypes.  Finally, we define a default trait function `flytrait` that just returns an instance of `CannotFly`.  Hence, all data types are automatically defined from the trait by default.

Now, when you do `@assign Duck with CanFly,CanSwim`, it is just translated to:

```julia
flytrait(::Duck) = CanFly()
swimtrait(::Duck) = CanSwim()
```

## Composite traits

Making composite traits is slightly more interesting.  It creates a new trait by combining multiple traits together.  Having a composite trait is defined as one that exhibits *all* of the underlying traits.  Hence, `@trait FlySwim as Ability with CanFly,CanSwim` would be translated to the following:

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

## Turning on verbose mode

If you feel this package is a little too magical, don't worry.  To make things
more transparent, you can turn on verbose mode.  All macro expansions are then
displayed automatically.

```julia
julia> BinaryTraits.set_verbose(true)
true

julia> @trait Iterable prefix Is,Not
┌ Info: Generated code
│   code =
│    quote
│        abstract type IterableTrait <: Any end
│        struct IsIterable <: IterableTrait
│        end
│        struct NotIterable <: IterableTrait
│        end
│        iterabletrait(x::Any) = begin
│                NotIterable()
│            end
│        BinaryTraits.istrait(::Type{IterableTrait}) = begin
│                true
│            end
│        nothing
└    end
```
