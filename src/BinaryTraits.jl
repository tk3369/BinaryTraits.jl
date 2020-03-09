module BinaryTraits

export @trait, @assign, @traitgroup

# prefix customizations

const prefix_map = Dict{Module,Dict{Symbol,Tuple{Symbol,Symbol}}}()

function get_prefix(m::Module, trait::Symbol)
    trait_dict = get!(prefix_map, m, Dict{Symbol,Tuple{Symbol,Symbol}}())
    return get!(trait_dict, trait, (:Can, :Cannot))
end

function set_prefix(m::Module, trait::Symbol, prefixes::Tuple{Symbol, Symbol})
    trait_dict = get!(prefix_map, m, Dict{Symbol,Tuple{Symbol,Symbol}}())
    return get!(trait_dict, trait, prefixes)
end

# macros

"""
    @trait <name> [as <category>] [prefixing <positive> <negative>]

Create a new abstract trait type named as `<name>Trait`.  Two subtypes
are automatically defined with `Can<name>` and `Cannot<name>`.

If the `as` clause is provided, then `category` (an abstract type)
will be used as the super type of the trait.
For example, `@trait Fly as Ability` is translated to:

```
abstract type FlyTrait <: Ability end
struct CanFly <: FlyTrait end
struct CannotFly <: FlyTrait end
flytrait(x) = CannotFly()
```

If the `prefixing` clause is provided, then it allows the user to choose different
prefixes than `Can` and `Cannot`.  For example, `@trait Iterable as Any prefixing Is Not`
is translated to:

```
abstract type IterableTrait <: Any end
struct IsIterable <: IterableTrait end
struct NotIterable <: IterableTrait end
iterabletrait(x) = NotIterable()
```
"""
macro trait(name, as_clause = :as, category = :Any,
            prefix_clause = :prefixing, prefixes::Expr = (:Can, :Cannot))

    usage = "Invalid trait usage. See doc string for this macro."
    pos, neg = prefixes.args

    typeof(name) === typeof(as_clause) === typeof(category) ===
        typeof(prefix_clause) === Symbol || error(usage)
    as_clause === :as || error(usage)
    prefix_clause === :prefixing || error(usage)

    trait_type = Symbol("$(name)Trait")
    can_type = Symbol("$(pos)$(name)")
    cannot_type = Symbol("$(neg)$(name)")
    lower_name = lowercase(String(name))
    default_trait_function = Symbol("$(lower_name)trait")

    set_prefix(__module__, name, (pos, neg))

    return esc(quote
        abstract type $trait_type <: $category end
        struct $can_type <: $trait_type end
        struct $cannot_type <: $trait_type end
        $(default_trait_function)(::Any) = $(cannot_type)()
        nothing
    end)
end

"""
    @assign [type] with [trait1, trait2, ...]

Assign traits to a data type.  For example, `@assign Duck with Fly,Swim`
is translated to:

```
flytrait(::Duck) = CanFly()
swimtrait(::Duck) = CanSwim()
```
"""
macro assign(T::Symbol, with::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid @assign usage.  Try something like: @assign Duck with Fly,Swim"
    with === :with || error(usage)

    expressions = Expr[]
    trait_syms = traits isa Expr ? traits.args : [traits]
    for t in trait_syms
        trait_function = Symbol(lowercase("$(t)trait"))
        prefix = get_prefix(__module__, t)[1]
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
    @traitgroup <name> as <trait1, trait2, ...> [prefixing <positive> <negatie>]

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

The `prefixing` clause is used to customize the positive/negative prefixes
in the trait types rather than the default Can/Cannot.
"""
macro traitgroup(name::Symbol, as::Symbol, traits::Expr,
                 prefix_clause = :prefixing, pos = :Can, neg = :Cannot)
    usage = "Invalid @traitgroup usage. See doc string for details."
    as === :as || error(usage)
    prefix_clause === :prefixing || error(usage)

    trait_type = Symbol("$(name)Trait")
    can_type = Symbol("$(pos)$(name)")
    cannot_type = Symbol("$(neg)$(name)")
    lower_name = lowercase(String(name))
    default_trait_function = Symbol("$(lower_name)trait")

    # Construct something like: flytrait(x) === CanFly() && swimtrait(x) === CanSwim()
    traits_func_names = [Symbol(lowercase("$(sym)trait")) for sym in traits.args]
    traits_can_types  = [Symbol("$(get_prefix(__module__, sym)[1])$(sym)")
        for sym in traits.args]
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
