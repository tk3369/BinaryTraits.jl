## Basic machinery

The machinery is extremely simple. When you define a traits like `@trait Fly`, it literally expands to the following code:

```julia
abstract type Fly end
trait(::Type{Fly}, T::Type) = Negative{Fly}()
is_trait(::Type{Fly}) = true
```

As you can see, a new abstract type called  `Fly` is automatically generated. By default, the `trait` function just returns an instance of `Negative{Fly}`.  Now, when you do `@assign Duck with Can{Fly},Can{Swim}`, it is expanded to the following:

```julia
trait(::Type{Fly}, ::Type{<:Duck}) = Can{Fly}()
trait(::Type{Swim}, ::Type{<:Duck}) = Can{Swim}()
```

!!! note
    There are several aliases defined for the `Positive` parametric type
    e.g. `Can`, `Has`, and `Is`.  See `BinaryTraits.Prefix` sub-module
    for the complete list of aliases.  The aliases are not exported by
    default, and you are expected to import only the ones that you need.

## Composite traits

Making composite traits is slightly more interesting.  It creates a new trait by combining multiple traits together.  Having a composite trait is defined as one that exhibits *all* of the underlying traits.  Hence, `@trait FlySwim with Can{Fly},Can{Swim}` would be translated to the following:

```julia
abstract type FlySwim end

function trait(::Type{FlySwim}, T::Type)
    if trait(Fly,T) === Can{Fly}() && trait(Swim,T) === Can{Swim}()
        Positive{FlySwim}()
    else
        Negative{FlySwim}()
    end
end

is_trait(::Type{FlySwim}) = true
```

## Turning on verbose mode

If you feel this package is a little too magical, don't worry.  To make things
more transparent, you can turn on verbose mode.  All macro expansions are then
displayed automatically.

```julia
julia> BinaryTraits.set_verbose!(true)
true

julia> @trait Iterable
┌ Info: Generated code
│   code =
│    quote
│        abstract type Iterable <: Any end
│        BinaryTraits.trait(::Type{Iterable}, T::Type) = begin
│                Negative{Iterable}()
│            end
│        BinaryTraits.is_trait(::Type{Iterable}) = begin
│                true
│            end
│        nothing
└    end
```
