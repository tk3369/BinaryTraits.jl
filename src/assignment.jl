
"""
    traits(m::Module, T::Assignable)

Returns a set of traits that the data type `T` exhibits, including
the ones that were assigned to any supertypes of `T`.
See also [`@assign`](@ref).
"""
function traits(m::Module, T::Assignable)
    _traits_map = collect(pairs(get_traits_map(m)))
    traits_map = sort(_traits_map; by = p -> _depth(first(p)))
    base = Set{DataType}()
    for (Tmap, s) in traits_map
        if T <: Tmap
            for trait in s
                T_new = binary_trait_type(trait)
                filter!(t -> !(binary_trait_type(t) <: T_new), base)
            end
            union!(base, s)
        end
    end
    return base
end

"""
    assign(m::Module, T::Assignable, trait::DataType)

Assign data type `T` with the specified trait.
"""
function assign(m::Module, T::Assignable, trait::DataType)
    push_traits_map!(m, T, trait)
    return nothing
end


"""
    @assign <T> with <trait1, trait2, ...>

Assign traits to the data type `T`.  The traits may be
positive or negative e.g. `Can{Fly}` or `Cannot{Swim}`.
"""
macro assign(T::Union{Expr,Symbol}, with::Symbol, traits::Union{Expr,Symbol})
    usage = "Invalid usage: try something like `@assign Duck with Can{Fly}`"
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
