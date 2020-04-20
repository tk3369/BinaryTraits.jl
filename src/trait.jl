
const DEFAULT_TRAIT_SUPERTYPE = Any

# -----------------------------------------------------------------------------

"Create a new prefix map"
make_prefix_map() = PrefixMap()

"Get a reference to the module's composite trait map."
function get_prefix_map(m::Module)
    isdefined(m, :__binarytraits_prefix_map) || error("Bug, no trait has been defined for module $m yet")
    return m.__binarytraits_prefix_map
end

"""
    prefixes(m::Module, trait::Symbol)

Find the prefixes `trait` from the client module `m`.
"""
prefixes(m::Module, trait::Symbol) = get_prefix_map(m)[trait]

# :Fly => :Can
can_prefix(m::Module, trait::Symbol) = prefixes(m, trait)[1]

# :Fly => :CanFly
can_type_symbol(m::Module, trait::Symbol) = Symbol(String(can_prefix(m, trait)) * String(trait))

# -----------------------------------------------------------------------------

"Create a new composite trait map"
make_composite_trait_map() = CompositeTraitMap()

"Get a reference to the module's composite trait map."
function get_composite_trait_map(m::Module)
    isdefined(m, :__binarytraits_composite_trait_map) || error("Bug, no trait has been defined for module $m yet")
    return m.__binarytraits_composite_trait_map
end

# -----------------------------------------------------------------------------

"""
    @trait <name> [as <category>] [prefix <positive>,<negative>] [with <trait1,trait2,...>]

Create a new trait type for `name` called `\$(name)Trait`:
* If the `as` clause is provided, then `category` (an abstract type) will be used as the super type of the trait type.
* If the `prefix` clause is provided, then it allows the user to choose different prefixes than the default ones (`Can` and `Cannot`) e.g. `prefix Is,Not` or `prefix Has,Not`.
* If the `with` clause is provided, then it defines a composite trait from existing traits. Note that you must specify at least 2 traits to make a composite trait.
"""
macro trait(name::Symbol, args...)
    category, prefixes, underlying_traits = parse_trait_args(args)
    pos, neg = prefixes.args

    trait_type = trait_type_name(name)
    this_can_type = Symbol("$(pos)$(name)")
    this_cannot_type = Symbol("$(neg)$(name)")
    lower_name = lowercase(String(name))

    # The default is "cannot".  But if it's a composite trait, then the
    # default is "can" only when all of it's underlying traits are also "can".
    default_trait_function = trait_func_name(name)
    default_expr = if underlying_traits !== nothing
        # Construct something like: flytrait(x) === CanFly() && swimtrait(x) === CanSwim()
        traits_func_names = [trait_func_name(sym) for sym in underlying_traits.args]
        traits_can_types  = [can_type_symbol(__module__, sym) for sym in underlying_traits.args]
        condition =
            Expr(:(&&),
                [Expr(:call, :(===), Expr(:call, f, :x), Expr(:call, g))
                        for (f,g) in zip(traits_func_names, traits_can_types)]...)

        # Consruct exprssion like: [condition] ? CanFlySwim() : CannotFlySwim()
        Expr(:if, condition, Expr(:call, this_can_type), Expr(:call, this_cannot_type))
    else
        # The default is "cannot" for every type
        Expr(:call, this_cannot_type)
    end

    # If it's composite trait, then I want to maintain a mapping from the
    # can-type to the underlying's can-types.  It is needed for interface checks.
    composite_expr = if underlying_traits !== nothing
        traits_can_types = [can_type_symbol(__module__, sym) for sym in underlying_traits.args]
        :( __binarytraits_composite_trait_map[$this_can_type] = Set([$(traits_can_types...)]) )
    else
        :()
    end

    prefixes = (pos, neg)
    name_node = QuoteNode(name)

    expr = quote
        abstract type $trait_type <: $category end
        struct $this_can_type <: $trait_type end
        struct $this_cannot_type <: $trait_type end
        $(default_trait_function)(x::Any) = $default_expr

        BinaryTraits.istrait(::Type{$trait_type}) = true

        # Remember trait prefixes in client module
        global __binarytraits_prefix_map
        if !@isdefined(__binarytraits_prefix_map)
            __binarytraits_prefix_map = BinaryTraits.make_prefix_map()
        end
        __binarytraits_prefix_map[$name_node] = $prefixes

        # Remember composite can-trait mappings in client module
        global __binarytraits_composite_trait_map
        if !@isdefined(__binarytraits_composite_trait_map)
            __binarytraits_composite_trait_map = BinaryTraits.make_composite_trait_map()
        end
        $composite_expr

        nothing
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
