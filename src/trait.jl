
const DEFAULT_TRAIT_SUPERTYPE = Any

export trait

abstract type BinaryTrait{T} end

# This sub-module is used to keep standard prefix types
module Prefix
    import ..BinaryTraits
    using ..BinaryTraits: BinaryTrait

    # default types for both sides
    struct Positive{T} <: BinaryTrait{T} end
    struct Negative{T} <: BinaryTrait{T} end

    # Positive/Negative trait types are traits
    BinaryTraits.is_trait(::Type{Positive{T}}) where T = true
    BinaryTraits.is_trait(::Type{Negative{T}}) where T = true

    # Optional positive types that may be brought into user module namespace
    const Can = Positive
    const Has = Positive
    const Is = Positive

    # Optional negative types that may be brought into user module namespace
    const Cannot = Negative
    const IsNot = Negative
    const No = Negative
    const Not = Negative
end

"""
    trait(::Type{T}, x)

Returns the singleton positive/negative trait type for object `x`.
"""
function trait end

# -----------------------------------------------------------------------------

"""
    @trait <name> [as <category>] [prefix <positive>,<negative>] [with <trait1,trait2,...>]

Create a new trait type for `name` called `\$(name)Trait`:
* If the `as` clause is provided, then `category` (an abstract type) will be used as the
  super type of the trait type.
* If the `prefix` clause is provided, then it allows the user to choose different prefixes
  than the default ones (`Can` and `Cannot`) e.g. `prefix Is,Not` or `prefix Has,Not`.
* If the `with` clause is provided, then it defines a composite trait from existing traits.
Note that you must specify at least 2 traits to make a composite trait.
"""
macro trait(name::Symbol, args...)
    category, prefixes, underlying_traits = parse_trait_args(args)
    pos, neg = prefixes.args
    mod = __module__

    # Try to import the predefined prefix types to user module's namespace
    import_prefix_type(mod, pos)
    import_prefix_type(mod, neg)

    this_can_type = Expr(:curly, pos, name)
    this_cannot_type = Expr(:curly, neg, name)

    # Single traits - the default is "cannot".
    # Composite traits - the default is the AND-expression of all underlyings.
    default_expr = if underlying_traits !== nothing
        # Composite trait here:
        # Construct something like: trait(Fly,x) === Can{Fly}() && trait(Swim,x) === Can{Swim}()
        condition =
            Expr(:(&&),
                [let cap = t.args[1], trait = t.args[2]
                    :( BinaryTraits.trait($trait, x) === $(cap){$trait}())
                 end for t in underlying_traits.args]...)
        # Construct expression like: [condition] ? Can{FlySwim}() : Cannot{FlySwim}()
        Expr(:if, condition, Expr(:call, this_can_type), Expr(:call, this_cannot_type))
    else
        # Single trait here: default to "cannot" for every type
        Expr(:call, this_cannot_type)
    end

    # If it's composite trait, then I want to maintain a mapping from the
    # positive trait type to the underlying's positive trait types.
    # It is needed for interface checks later.
    composite_expr = if underlying_traits !== nothing
        underlying_types = underlying_traits.args
        quote
            BinaryTraits.push_composite_map!($mod, $this_can_type, Set([$(underlying_types...)]))
        end
    else
        nothing
    end

    expr = quote
        abstract type $name <: $category end
        BinaryTraits.trait(::Type{$name}, x::Type) = $default_expr
        BinaryTraits.is_trait(::Type{$name}) = true
        $composite_expr
    end

    display_expanded_code(expr)
    return esc(expr)
end

"""
Parse arguments for the @trait macro.
"""
function parse_trait_args(args)

    category = Symbol(DEFAULT_TRAIT_SUPERTYPE)
    prefixes = Expr(:tuple, :Positive, :Negative)
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
        (traits isa Symbol || is_tuple_of_curly_expressions(traits; n = 2, op = >=)) ||
            throw(SyntaxError(usage))
        args = args[3:end]
    end

    return (category, prefixes, traits)
end

"""
    import_prefix_type(m::Module, prefix::Symbol)

Import predefined prexies `prefix` from BinaryTraits.Prefix module into
the specified module `m`. If the name is already bounded with a different value
in the module, an error is raised.
"""
function import_prefix_type(m::Module, prefix::Symbol)
    existing_names = names(m, all = true, imported = true)
    try
        prefix_type = Base.eval(m, prefix)
        parentmodule(prefix_type) == BinaryTraits.Prefix ||
            error("Unable to import prefix `$prefix` as it already exists in module $m")
    catch
        Base.eval(m, :(import BinaryTraits.Prefix: $prefix))
    end
end
