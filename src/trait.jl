
const DEFAULT_TRAIT_SUPERTYPE = Any

export Can, Cannot, Is, Not
abstract type AbstractTrait{T} end
struct Can{T} <: AbstractTrait{T} end
struct Cannot{T} <: AbstractTrait{T} end

# aliases
const Is{T} = Can{T}
const Has{T} = Can{T}
const Not{T} = Cannot{T}
const Lack{T} = Cannot{T}


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

    trait_type = trait_type_name(name)
    this_can_type = Expr(:curly, :Can, trait_type) #Symbol("$(pos)$(name)")
    this_cannot_type = Expr(:curly, :Cannot, trait_type) # Symbol("$(neg)$(name)")
    lower_name = lowercase(String(name))

    # The default is "cannot".  But if it's a composite trait, then the
    # default is "can" only when all of it's underlying traits are also "can".
    default_trait_function = trait_func_name(name)
    default_expr = if underlying_traits !== nothing
        # Construct something like: flytrait(x) === CanFly() && swimtrait(x) === CanSwim()
        traits_func_names = [trait_func_name(mod, sym) for sym in underlying_traits.args]
        traits_can_types  = underlying_traits.args
        condition =
            Expr(:(&&),
                [Expr(:call, :(===), Expr(:call, f, :x), Expr(:call, g))
                        for (f,g) in zip(traits_func_names, traits_can_types)]...)

        # Construct expression like: [condition] ? CanFlySwim() : CannotFlySwim()
        Expr(:if, condition, Expr(:call, this_can_type), Expr(:call, this_cannot_type))
    else
        # The default is "cannot" for every type
        Expr(:call, this_cannot_type)
    end

    # If it's composite trait, then I want to maintain a mapping from the
    # can-type to the underlying's can-types.  It is needed for interface checks.
    composite_expr = if underlying_traits !== nothing
        traits_can_types = underlying_traits.args
        quote
        BinaryTraits.push_composite_map!($mod, $this_can_type, Set([$(traits_can_types...)]))
        end
    else
        nothing
    end

    prefixes = (pos, neg)
    name_node = QuoteNode(name)

    expr = quote
        abstract type $trait_type <: $category end
        # struct $this_can_type <: $trait_type end
        # struct $this_cannot_type <: $trait_type end
        $(default_trait_function)(x::Any) = $default_expr

        # BinaryTraits.istrait(::Type{$trait_type}) = true

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
