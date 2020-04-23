
"Create a new traits map"
make_traits_map() = TraitsMap()
const EMPTY_TRAITS_MAP = Base.ImmutableDict{Assignable,Set{DataType}}()

"Get a reference to the module's composite trait map."
function get_traits_map(m::Module)
    if isdefined(m, :__binarytraits_traits_map)
        m.__binarytraits_traits_map
    else
        EMPTY_TRAITS_MAP
    end
end

"""
    traits(m::Module, T::Assignable)

Returns a set of Can-types that the data type `T` exhibits.  Look through
the composite traits and return the union of all Can-types as such.
See also [`@assign`](@ref).
"""
function traits(m::Module, T::Assignable)
    traits_map = get_traits_map(m)
    base = Set{DataType}()
    for (Tmap, s) in pairs(traits_map)
        if T <: Tmap
            union!(base, s)
        end
    end
    return base
end

"""
    assign(m::Module, T::Assignable, can_type::DataType)

Assign data type `T` with the specified Can-type from a trait.
"""
function assign(m::Module, T::Assignable, can_type::DataType)
    traits_map = get_traits_map(m)
    traits_set = get!(traits_map, T) do; Set{DataType}() end
    push!(traits_set, can_type)
    return nothing
end


"""
    @assign <T> with <Trait1, Trait2, ...>

Assign traits to the data type `T`.  For example:

```julia
@assign Duck with Fly,Swim
```

is translated to something like:

```julia
flytrait(::Duck) = CanFly()
swimtrait(::Duck) = CanSwim()
```

where `x` is the name of the trait `X` in all lowercase, and `T` is the type
being assigned with the trait `X`.
"""
macro assign(T::Union{Expr,Symbol}, with::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid @assign usage.  Try something like: @assign Duck with Fly,Swim"
    with === :with || throw(SyntaxError(usage))
    mod = __module__

    assign_impl(mod, T, traits)
end

function assign_impl(mod, T, traits)
    expressions = Expr[]
    trait_syms = traits isa Expr && traits.head == :tuple ? traits.args : [traits]
    for this_can_type in trait_syms
        trait_function = trait_func_name(mod, this_can_type)

        # Add an expression like: <trait>trait(::T) = Can<Trait>()
        # e.g. flytrait(::Duck) = CanFly()
        push!(expressions,
            Expr(:(=),
                Expr(:call, trait_function, Expr(:(::), T)),
                Expr(:call, this_can_type)))

        # e.g. BinaryTraits.assign(MyModule, Duck, CanFly)
        push!(expressions,
                quote
                    BinaryTraits.assign($mod, $T, $this_can_type)
                end)
    end

    expr = quote
        # ensure that traits map is allocated
        global __binarytraits_traits_map
        if !@isdefined(__binarytraits_traits_map)
            __binarytraits_traits_map = BinaryTraits.make_traits_map()
        end
        # call assign function
        $(expressions...)
        nothing
    end

    display_expanded_code(expr)
    return esc(expr)
end
