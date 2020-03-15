module BinaryTraits

using MacroTools

export @trait, @assign
export istrait

const VERBOSE = Ref(false)

"""
    istrait(x)

Return `true` if x is a trait.  This function is expected to be extended by
users for their trait types.  The extension is automatic when the
[`@trait`](@ref) macro is used.
"""
istrait(x::DataType) = false

# Debugging

function set_verbose(b::Bool)
    VERBOSE[] = b
end

# types

struct SyntaxError <: Exception
    msg
end

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

# macros for our domain specific language

"""
    @trait <name> [as <category>] [prefix <positive>,<negative>] [with <trait1,trait2,...>]

Create a new trait type for `name` called `\$(name)Trait`.

* If the `as` clause is provided, then `category` (an abstract type) will be used as the super type of the trait type.

* If the `prefix` clause is provided, then it allows the user to choose different prefixes than the default ones (`Can` and `Cannot`) e.g. `prefix Is,Not` or `prefix Has,Not`.

* If the `with` clause is provided, then it defines a composite trait from existing traits. Note that you must specify at least 2 traits to make a composite trait.
"""
macro trait(name::Symbol, args...)
    category, prefixes, traits = parse_trait_args(args)
    pos, neg = prefixes.args

    trait_type = Symbol("$(name)Trait")
    can_type = Symbol("$(pos)$(name)")
    cannot_type = Symbol("$(neg)$(name)")
    lower_name = lowercase(String(name))
    default_trait_function = Symbol("$(lower_name)trait")

    set_prefix(__module__, name, (pos,neg))

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

    expr = quote
        abstract type $trait_type <: $category end
        struct $can_type <: $trait_type end
        struct $cannot_type <: $trait_type end
        BinaryTraits.istrait(::Type{$trait_type}) = true
        $(default_trait_function)(x::Any) = $default_expr
        nothing
    end
    display_expanded_code(expr)
    return esc(expr)
end

"""
    @assign <T> with <Trait1, Trait2, ...>

Assign traits to the data type `T`.  Translated to something like:

    <x>trait(::T) = Can<X>()

where `x` is the name of the trait `X` in all lowercase, and `T` is the type being assigned with the trait `X`.
"""
macro assign(T::Symbol, with::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid @assign usage.  Try something like: @assign Duck with Fly,Swim"
    with === :with || throw(SyntaxError(usage))

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
    expr = quote
        $(expressions...)
        nothing
    end
    display_expanded_code(expr)
    return esc(expr)
end

function display_expanded_code(expr)
    if VERBOSE[]
        code = MacroTools.postwalk(rmlines, expr)
        @info "Generated code" code
    end
    return nothing
end

"""
Parse arguments for the @trait macro.
"""
function parse_trait_args(args)

    category = :Any
    prefixes = Expr(:tuple, :Can, :Cannot)
    traits = nothing

    usage = "Invalid @trait usage. See doc string for details."
    length(args) % 2 === 0 || throw(SyntaxError(usage))

    if length(args) > 0 && args[1] == :as
        category = args[2]
        category isa Symbol || throw(SyntaxError("Not a symbol: $category. $usage"))
        args = args[3:end]
    end

    if length(args) > 0 && args[1] == :prefix
        prefixes =  args[2]
        is_tuple_of_symbols(prefixes; n = 2) || throw(SyntaxError(usage))
        args = args[3:end]
    end

    if length(args) > 0 && args[1] == :with
        traits =  args[2]
        (traits isa Symbol || is_tuple_of_symbols(traits; n = 2, op = >=)) ||
            throw(SyntaxError(usage))
        args = args[3:end]
    end

    return (category, prefixes, traits)
end

"""
Check if `x` is an expression of a tuple of symbols.
If `n` is specified then also check whether the tuple
has `n` elements. The `op` argument is used to customize
the check against `n`. Use `>=` or `<=` to check min/max
constraints.
"""
function is_tuple_of_symbols(x; n = nothing, op = isequal)
    x isa Expr &&
    x.head == :tuple &&
    all(x -> x isa Symbol, x.args) &&
    (n === nothing || op(length(x.args), n))
end

end # module
