"""
    Assignable

`Assignable` represents any data type that can be associated with traits.
It essentially covers all data types including parametric types e.g. `AbstractArray`
"""
const Assignable = Union{UnionAll, DataType}

"""
    Contract{T <: DataType, F <: Function, N}

A contract refers to a function defintion `func` that is required to satisfy
the Can-type of a trait. The function `func` must accepts `args` and returns `ret`.

# Fields
- `can_type`: can-type of a trait e.g. `CanFly`
- `func`: function that must be implemented to satisfy this trait
- `args`: argument types of the function `func`
- `kwargs`: keyword argument names of the function `func`
- `ret`: return type of the function `func`
"""
struct Contract{T <: DataType, F <: Function}
    can_type::T
    func::F
    args::Tuple
    kwargs::Tuple
    ret::Union{DataType,Nothing}
end

function Base.show(io::IO, c::Contract)
    typ = Symbol(TYPE_PLACEHOLDER)
    args = string("(", join([typ, c.args...], ", ::"))
    if length(c.kwargs) > 0
        args = string(args, "; ", join(c.kwargs, ", "))
    end
    args = string(args, ")")
    trait = supertype(c.can_type)
    print(io, "$(trait): $(c.can_type) ⇢ $(c.func)$(args)")
    c.ret !== nothing && print(io, "::$(c.ret)")
end

"""
    InterfaceReview

An InterfaceReview object contains the validation results of an interface.

# Fields
- `type`: the type being checked
- `result`: true if the type fully implements all required contracts
- `implemented`: an array of implemented contracts
- `misses`: an array of unimplemented contracts
"""
@Base.kwdef struct InterfaceReview
    type::Assignable
    result::Bool
    implemented::Vector{Contract}
    misses::Vector{Contract}
end

function Base.show(io::IO, ir::InterfaceReview)
    T = InterfaceReview
    irtype = ir.type
    if length(ir.implemented) == length(ir.misses) == 0
        print(io, "✅ $(irtype) has no interface contract requirements.")
    end
    if length(ir.implemented) > 0
        println(io, "✅ $(irtype) has implemented:")
        for (i, c) in enumerate(ir.implemented)
            println(io, "$(i). $c")
        end
    end
    if length(ir.misses) > 0
        println(io, "❌ $(irtype) is missing these implementations:")
        for (i, c) in enumerate(ir.misses)
            println(io, "$(i). $c")
        end
    end
end

"""
    SyntaxError

Syntax error for macros.
"""
struct SyntaxError <: Exception
    msg
end

"""
    TraitsMap

Map a data type to the Can-type of its assigned traits.
For example, `Dog => Set([CanSwim, CanRun])`.
"""
const TraitsMap = Dict{Assignable,Set{DataType}}

"""
    InterfaceMap

Map a Can-type to a set of interface contracts.  See [`Contract`](@ref).
"""
const InterfaceMap = Dict{DataType,Set{Contract}}

"""
    PrefixMap

Maps a prefix symbol to the positive/negatiave prefix symbols
e.g. `:Fly => (:Can, :Cannot)`.
"""
const PrefixMap = Dict{Symbol,Tuple{Symbol,Symbol}}

"""
    CompositeTraitMap

Maps a composite can-type to a set of its underlying can-types.
e.g. `CanFlySwim => Set([CanFly, CanSwim])`.
"""
const CompositeTraitMap = Dict{DataType,Set{DataType}}
