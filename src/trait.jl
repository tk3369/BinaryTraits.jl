
const DEFAULT_TRAIT_SUPERTYPE = Any

export Positive, Negative
export trait

abstract type AbstractTrait{T} end
struct Positive{T} <: AbstractTrait{T} end
struct Negative{T} <: AbstractTrait{T} end

# This sub-module is used to keep prefix types
module Prefix
    using ..BinaryTraits: Positive, Negative
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
macro trait(trait_type::Symbol, args...)
    category, prefixes, underlying_traits = parse_trait_args(args)
    pos, neg = prefixes.args
    mod = __module__

    ensure_binary_trait_prefix_type(:Positive, pos)
    ensure_binary_trait_prefix_type(:Negative, neg)

    this_can_type = Expr(:curly, pos, trait_type)
    this_cannot_type = Expr(:curly, neg, trait_type)

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
        # Construct expression like: [condition] ? CanFlySwim() : CannotFlySwim()
        Expr(:if, condition, Expr(:call, this_can_type), Expr(:call, this_cannot_type))
    else
        # Single trait here: default to "cannot" for every type
        Expr(:call, this_cannot_type)
    end

    # If it's composite trait, then I want to maintain a mapping from the
    # can-type to the underlyings.  It is needed for interface checks.
    composite_expr = if underlying_traits !== nothing
        underlying_types = underlying_traits.args
        quote
            BinaryTraits.push_composite_map!($mod, $this_can_type, Set([$(underlying_types...)]))
        end
    else
        nothing
    end

    expr = quote
        abstract type $trait_type <: $category end
        BinaryTraits.trait(::Type{$trait_type}, x::Any) = $default_expr
        BinaryTraits.istrait(::Type{$trait_type}) = true
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

# XXX Auto-piracy: define trait prefix type in BinaryTraits.Prefix
function ensure_binary_trait_prefix_type(side, T)
    try
        Base.eval(BinaryTraits.Prefix, T)
    catch
        # @info "$T doesn't exist.... defining it now"
        Base.eval(BinaryTraits.Prefix, quote
            const $T{S} = $side{S}
            export $T
        end)
        Base.eval(BinaryTraits, quote
            using .Prefix: $T
            export $T
        end)
    end
    nothing
end
