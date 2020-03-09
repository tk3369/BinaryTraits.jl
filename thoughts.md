# Random Thoughts

This file contains other random thoughts about what else we could do with this package.

## Trait interfaces

It is useful to define what a trait entails for a type.  For example, we may mandate a type that has the `Fly` trait to implement the following functions:

- `speed`: return the top speed when flying
- `liftoff`: start flying
- etc.

So, if a `Duck` `CanFly`, then there should be functions defined as such:

- `speed(::Duck)`
- `liftoff(::Duck)`

Of course, there could be cases where multiple arguments are needed. For example,

- `speed(::Duck, altitude::Float64, wind_direction::Float64)`

This design is pretty much how a single-dispatch CBOO language usually handles interface definitions. Given that Julia supports multiple dispatch, it becomes more interesting when a trait involves multiple types.

Notes:

As an example, let's consider an explosion that might happen when you mix two  chemicals.  We may have an `explode(::HasAmmonia, ::HasBleach)` function to model that behavior.  So, which type has the trait?  Not Ammonia.  Not Bleach.  It's the combination of both types that exhibit the trait.

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

Perhaps BinaryTraits can keep track of all user defined traits (just like how it keeps track of trait prefixes).  Then, the check above can be fully automated with a single function call during module initialization.
