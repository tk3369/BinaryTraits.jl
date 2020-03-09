# Trait specification

It is useful to define what a trait entails for a type.  For example, we may mandate a type that has the `Fly` trait to implement the following functions:

- `speed`: return the top speed when flying
- `liftoff`: start flying
- etc.

So, if a `Duck` `CanFly`, then there should be functions defined as such:

- `speed(::Duck)`
- `liftoff(::Duck)`

Of course, there could be cases where multiple arguments are needed. For example,

- `speed(::Duck, altitude::Float64, wind_direction::Float64)`

This design is pretty much how a CBOO language usually handles interface definitions. Given that Julia supports multiple dispatch, it becomes more interesting when a trait involves multiple types.

Notes:

As an example, let's consider an explosion that might happen when you mix two  chemicals.  We may have an `explode(::Ammonia, ::Bleach)` function to model that behavior.  So, which type has the trait?  Not Ammonia.  Not Bleach.  It's the combination of both types that exhibit the trait.

It seems to be quite messy if we have to support multi-datatype traits.


# Interface

First, define interface functions

```julia
"Return top speed in unit of meters/second"
function speed end

"Lift off before flying"
function liftoff end

"Diving into water"
function dive end
```

# Trait definitions

```julia
@trait Fly as Ability implements speed, liftoff
@trait Swim as Ability implements speed, dive
```

The above code is translated to:

```julia
abstract type FlyTrait <: Ability end
struct CanFly <: FlyTrait end
struct CannotFly <: FlyTrait end
flytrait(x) = CannotFly()
traitfuncs(::CanFly) = [speed, liftoff]
```

# Trait assignments

```julia
@assign Duck with Fly, Swim
```

It is then translated to:
```julia
  flytrait(::Duck) = CanFly()
  swimtrait(::Duck) = CanSwim()
  traitfuncs(::Duck) = [speed, liftoff, dive]
```

# Trait implementation check

So it's possible to check all types with something like:

```julia
for T in user_defined_types
  for t in cantraits(T)
     for f in traitfuncs(t)
         method_defined(f, T) || error("T does not implement functions $f for trait $t")
     end
  end
end
```

# Perhaps another syntax

```julia
@trait Fly as Ability = begin
    speed
    liftoff
end

@trait Swim as Ability = begin
    speed
    dive
end

@assign Duck with (Swim, Fly)
```
