
"Create a new traits map"
make_traits_map() = TraitsMap()

"Get a reference to the module's composite trait map."
function get_traits_map(m::Module)
    isdefined(m, :__binarytraits_traits_map) || error("Bug, traits map is missing.")
    return m.__binarytraits_traits_map
end

"""
    traits(m::Module, T::Assignable)

Returns a set of Can-types that the data type `T` exhibits.  Look through
the composite traits and return the union of all Can-types as such.
See also [`@assign`](@ref).
"""
function traits(m::Module, T::Assignable)
    traits_map = get_traits_map(m)
    base = get!(traits_map, T) do; Set{DataType}() end
    for (Tmap, s) in pairs(traits_map)
        if T !== Tmap && T <: Tmap
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
macro assign(T::Symbol, with::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid @assign usage.  Try something like: @assign Duck with Fly,Swim"
    with === :with || throw(SyntaxError(usage))

    expressions = Expr[]
    trait_syms = traits isa Expr ? traits.args : [traits]
    for t in trait_syms
        trait_function = trait_func_name(t)
        mod = __module__
        this_can_type = can_type_symbol(mod, t)

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

