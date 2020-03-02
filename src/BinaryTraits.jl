module BinaryTraits

export @trait, @assign, @traitgroup

"""
    @trait [name] as [category]

Create a new trait under a specific category (an abstract type).
For example, `@trait Fly as Ability` is translated to:

```
abstract type FlyTrait <: Ability end
struct CanFly <: FlyTrait end
struct CannotFly <: FlyTrait end
flytrait(x) = CannotFly()
```
"""
macro trait(name, as, category)

    usage = "invalid trait usage... try something like: @trait Fly as Ability"
    typeof(name) === typeof(as) === typeof(category) === Symbol || error(usage)
    as === :as || error(usage)

    trait_type = Symbol("$(name)Trait")
    can_type = Symbol("Can$(name)")
    cannot_type = Symbol("Cannot$(name)")
    lower_name = lowercase(String(name))
    default_trait_function = Symbol("$(lower_name)trait")

    return esc(quote
        abstract type $trait_type <: $category end
        struct $can_type <: $trait_type end
        struct $cannot_type <: $trait_type end
        $(default_trait_function)(::Any) = $(cannot_type)()
        nothing
    end)
end

# @assign Duck with Fly,Swim
# ...is translated to
#   flytrait(::Duck) = CanFly()
#   swimtrait(::Duck) = CanSwim()
"""
    @assign [type] with [trait1, trait2, ...]

Assign traits to a data type.  For example, `@assign Duck with Fly,Swim` is translated to:

```
flytrait(::Duck) = CanFly()
swimtrait(::Duck) = CanSwim()
```
"""
macro assign(T::Symbol, with::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid @assign usage.  Try something like: @assign Duck with Fly,Swim"
    with === :with || error(usage)
    return _assign(T, traits, "Can")
end

# @unassign Dog from Fly,Speak
# ...is translated to
#   flytrait(::Dog) = CannotFly()
#   speaktrait(::Dog) = CannotSpeak()
#
# CAUTION: This is probably not a good idea.  State should not be maintained
#   changing function definitions.
macro unassign(T::Symbol, from::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid @unassign usage.  Try something like: @unassign Duck from Fly"
    from === :from || error(usage)
    return _assign(T, traits, "Cannot")
end

# Helper
function _assign(T, traits, prefix)
    expressions = Expr[]
    trait_syms = traits isa Expr ? traits.args : [traits]
    for t in trait_syms
        trait_function = Symbol(lowercase("$(t)trait"))
        can_type = Symbol("$prefix$t")
        push!(expressions,
            Expr(:(=),
                Expr(:call, trait_function, Expr(:(::), T)),
                Expr(:call, can_type)))
    end
    return esc(quote
        $(expressions...)
        nothing
    end)
end

"""
    @traitgroup [name] as [trait1, trait2, ...]

Create a composite traits from several other traits.  For example,
`@traitgroup FlySwim as Fly,Swim` is translated to:

```
abstract type FlySwimTrait end
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
"""
macro traitgroup(name::Symbol, as::Symbol, traits::Expr)
    usage = "Invalid @traitgroup usage.  Try something like: @traitgroup FlySwim as Fly,Swim"
    as === :as || error(usage)

    trait_type = Symbol("$(name)Trait")
    can_type = Symbol("Can$(name)")
    cannot_type = Symbol("Cannot$(name)")
    lower_name = lowercase(String(name))
    default_trait_function = Symbol("$(lower_name)trait")

    # Construct something like: flytrait(x) === CanFly() && swimtrait(x) === CanSwim()
    traits_func_names = [Symbol(lowercase("$(sym)trait")) for sym in traits.args]
    traits_can_types  = [Symbol("Can$(sym)") for sym in traits.args]
    condition =
        Expr(:(&&),
            [Expr(:call, :(===), Expr(:call, f, :x), Expr(:call, g))
                    for (f,g) in zip(traits_func_names, traits_can_types)]...)

    # Consruct exprssion like: [condition] ? CanFlySwim() : CannotFlySwim()
    if_expr = Expr(:if, condition, Expr(:call, can_type), Expr(:call, cannot_type))

    return esc(quote
        abstract type $trait_type end
        struct $can_type <: $trait_type end
        struct $cannot_type <: $trait_type end
        $(default_trait_function)(x) = $if_expr
        nothing
    end)
end

end # module
