module BinaryTraits

export @trait, @assign

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
    @trait <name> [as <category>] [prefix <positive>,<negative>] [with <trait1,trait2,...>]

Create a new trait for `name`.

* If the `as` clause is provided, then `category` (an abstract type) will be used as the super type of the trait type.

* If the `prefix` clause is provided, then it allows the user to choose different prefixes than the default ones (`Can` and `Cannot`) e.g. `prefix Is,Not` or `prefix Has,Not`.

* If the `with` clause is provided, then it defines a composite trait from existing traits. Note that you must specify at least 2 traits to make a composite trait.
"""
macro trait(name::Symbol, as::Symbol = :as, category::Symbol = :Any,
            prefix_clause = :prefix, prefixes::Expr = Expr(:tuple, :Can, :Cannot),
            with_clause::Symbol = :with, traits = nothing)

    usage = "Invalid @trait usage. See doc string for details."
    pos, neg = prefixes.args

    as === :as || error(usage)
    prefix_clause === :prefix || error(usage)

    trait_type = Symbol("$(name)Trait")
    can_type = Symbol("$(pos)$(name)")
    cannot_type = Symbol("$(neg)$(name)")
    lower_name = lowercase(String(name))
    default_trait_function = Symbol("$(lower_name)trait")

    default_expr = if traits !== nothing
        # Construct something like: flytrait(x) === CanFly() && swimtrait(x) === CanSwim()
        traits_func_names = [Symbol(lowercase("$(sym)trait")) for sym in traits.args]
        traits_can_types  = [Symbol("$(get_prefix(__module__, sym)[1])$(sym)")
            for sym in traits.args]
        condition =
            Expr(:(&&),
                [Expr(:call, :(===), Expr(:call, f, :x), Expr(:call, g))
                        for (f,g) in zip(traits_func_names, traits_can_types)]...)

        # Consruct exprssion like: [condition] ? CanFlySwim() : CannotFlySwim()
        Expr(:if, condition, Expr(:call, can_type), Expr(:call, cannot_type))
    else
        Expr(:call, cannot_type)
    end

    return esc(quote
        abstract type $trait_type <: $category end
        struct $can_type <: $trait_type end
        struct $cannot_type <: $trait_type end
        $(default_trait_function)(x::Any) = $default_expr
        nothing
    end)
end

"""
    @assign <T> with <trait1, trait2, ...>

Assign traits to the data type `T`.
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

end # module
