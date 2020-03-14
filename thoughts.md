# Random Thoughts

This file contains other random thoughts about what else we could do with this package.

## Trait interfaces

It is useful to define what a trait entails for a type.  For example, we may mandate a type that has the `Fly` trait to implement the following functions:

- `speed`: return the top speed when flying
- `liftoff`: start flying
- etc.

So, if a `Duck` `CanFly`, then there should be functions defined as such:

- `speed(::Duck)::Float64`
- `liftoff(::Duck)::Nothing`

Of course, there could be cases where multiple arguments are needed. For example,

- `speed(::Duck, altitude::Float64, wind_direction::Float64)::Float64`

This design is pretty much how a single-dispatch CBOO language usually handles interface definitions. Given that Julia supports multiple dispatch, it becomes more interesting when a trait involves multiple types.

Notes:

As an example, let's consider an explosion that might happen when you mix two  chemicals.  We may have an `explode(::HasAmmonia, ::HasBleach)::Effect` function to model that behavior.  So, which type has the trait?  Not Ammonia.  Not Bleach.  It's the combination of both types that exhibit the trait.

In that case, the user can define a combo trait, effectively fitting a multiple dispatch problem into a single dispatch setup.

## What to do as a user?

First, define interface functions

```julia
"Return top speed in unit of meters/second"
function speed end

"Lift off before flying"
function liftoff end

"Diving into water"
function dive end
```

Then, assign interface functions.

```julia
@interface Fly implements speed, liftoff
@interface Swim implements speed, dive
```

The above code is translated to:

```julia
traitfuncs(::CanFly) = [speed, liftoff]
traitfuncs(::CanSwim) = [speed, dive]
```

So it's possible to statically check all types in the user module's `__init__` function as follows:

```julia
for T in user_defined_types      # Duck
    for t in cantraits(T)        # [CanFly, CanSwim]
        for f in traitfuncs(t)   # [speed, liftoff, dive]
            is_method_defined(f, T) ||
                error("T does not implement functions $f for trait $t")
        end
    end
end
```

Perhaps BinaryTraits can keep track of all user defined traits (just like how it keeps track of trait prefixes).  Then, the check above can be fully automated with a single function call during module initialization e.g. `BinaryTraits.static_check()`.

## Strict function signatures

To support interfaces including arguments and return type, we would have to attach the function signature to the traits.  In Julia, function signatures are represented as tuples.  For example, for `speed(::CanFly)::Float64`, the signature would be:

```julia
Tuple{CanFly,Float64}
```

Multiple dispatch makes it slightly more complex, although with an opinionated design we can just say that the types are always sorted and placed in the front.  The `explode(::HasAmmonia, ::HasBleach)::Effect` would be represented as:

```julia
Tuple{HasAmonia,HasBleach,Effect}
```

So we need a way to specify the interface requirements.  The can-trait types must be accepted as the leading argument.

```julia
@interface Fly       speed(CanFly) → Float64
@interface Explosive explode(HasAmonia,HasBleach) → Effect
```

BinaryTraits can keep track of a "method table" that is assigned to each trait or combinations of traits.  If no implementation was fine during module initialization phase then a warning/error can be generated.

More elaborate syntax can be done as follows:

```julia
@interface Fly begin
    speed(CanFly) → Float64
    liftoff(CanFly) → Nothing
end
```

In order for a type to satisfy this `Fly` interface, it must implement all interface functions:

```julia
speed(d::Duck) = 0.2
liftoff(d::Duck) = flap_flap(d)
```

Note: The caveat is that Julia may not be able to infer the return type accurately (is this true?)

So how does it translate to actual code?

```julia
BinaryTraits.register(FlyTrait, speed, (CanFly, Float64))
BinaryTraits.register(ExplosiveTrait, explode, (HasAmonia, HasBleach, Effect))
```

