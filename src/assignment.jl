
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
    push_traits_map!(m, T, can_type)
    return nothing
end


"""
    @assign <T> with <CanTrait1, CanTrait2, ...>

Assign traits to the data type `T`.  For example:

```julia
@assign Duck with CanFly,CanSwim
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
    usage = "Invalid usage: try something like: @assign Duck with CanFly,CanSwim"
    with === :with || throw(SyntaxError(usage))
    mod = __module__

    assign_impl(mod, T, traits)
end

function assign_impl(mod, T, traits)

    # There are two possible AST cases:
    # 1. @assign T with Can{X}
    # 2. @assign T with Can{X},Can{Y},...
    #
    # The first case would be an Expr with head == :curly
    # The second case would be an Expr with head == :tuple and sub-expr of :curly's
    capabilities = if traits isa Expr && traits.head == :tuple
        [(side = x.args[1], trait = x.args[2]) for x in traits.args]
    elseif traits isa Expr && traits.head == :curly
        x = traits
        [(side = x.args[1], trait = x.args[2])]
    else
        throw(SyntaxError("Must assign types with trait can/cannot-types"))
    end

    # Build up expressions for each capability
    expressions = Expr[]
    for cap in capabilities
        push!(expressions,
                quote
                    BinaryTraits.trait(::Type{$(cap.trait)}, ::Type{<:$T}) =
                        $(cap.side){$(cap.trait)}()
                    BinaryTraits.assign($mod, $T, $(cap.side){$(cap.trait)})
                end)
    end

    expr = quote
        $(expressions...)
    end

    display_expanded_code(expr)
    return esc(expr)
end
