"""
    Assignable

`Assignable` represents any data type that can be associated with traits.
It essentially covers all data types including parametric types e.g. `AbstractArray`
"""
const Assignable = Union{UnionAll, DataType}

"""
    Contract{T <: DataType, F <: Function, N}

A contract refers to a function defintion `func` that is required to satisfy
a trait. The function `func` must accepts `args` and returns `ret`.

# Fields
- `trait`: a trait type e.g. `Can{Fly}` or `Cannot{Fly}`
- `func`: function that must be implemented to satisfy this trait
- `args`: argument types of the function `func`
- `kwargs`: keyword argument names of the function `func`
- `ret`: return type of the function `func`
"""
struct Contract{T <: DataType, F <: Function}
    trait::T
    func::F
    args::Tuple
    kwargs::Tuple
    ret::Union{DataType,Nothing}
end

function Base.show(io::IO, c::Contract)
    # Represent the trait type with a special symbol
    args = [x == c.trait ? "🔹" : "::$x" for x in c.args]
    args = string("(", join(args, ", "))
    if length(c.kwargs) > 0
        args = string(args, "; ", join(c.kwargs, ", "))
    end
    args = string(args, ")")
    trait = supertype(c.trait)
    print(io, "$(trait): $(c.trait) ⇢ $(c.func)$(args)")
    c.ret !== nothing && print(io, "::$(c.ret)")
end

"""
    InterfaceReview

An InterfaceReview object contains the validation results of an interface.

# Fields
- `data_type`: the type being checked
- `result`: true if the type fully implements all required contracts
- `implemented`: an array of implemented contracts
- `misses`: an array of unimplemented contracts
"""
@Base.kwdef struct InterfaceReview
    data_type::Assignable
    result::Bool
    implemented::Vector{Contract}
    misses::Vector{Contract}
end

function Base.show(io::IO, ir::InterfaceReview)
    irtype = ir.data_type
    if length(ir.implemented) == length(ir.misses) == 0
        print(io, "✅ $(irtype) has no interface contract requirements.")
        return
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

const MyDict = VERSION < v"1.2.0" ? Dict : IdDict

"""
    TraitsMap

Map a data type to the its assigned traits.
For example, `Dog => Set([Can{Swim}, Can{Run}, Cannot{Fly}])`.
"""
const TraitsMap = MyDict{Assignable,Set{DataType}}

"""
    InterfaceMap

Map a trait to a set of interface contracts.  See [`Contract`](@ref).
"""
const InterfaceMap = MyDict{DataType,Set{Contract}}

"""
    CompositeTraitMap

Maps a composite positive trait type to a set of its underlying traits,
which could be positive or negative.
e.g. `Is{Fish} => Set([Can{Swim}, Cannot{Fly}])`.
"""
const CompositeTraitMap = MyDict{DataType,Set{DataType}}

"""
    TraitsStorage

Keeps all traits-related dynamic data.

# Fields
- `traits_map`: see [`TraitsMap`](@ref)
- `interface_map`: see [`InterfaceMap`](@ref)
- `composite_map`: see [`CompositeTraitMap`](@ref)
"""
struct TraitsStorage
    traits_map::TraitsMap
    interface_map::InterfaceMap
    composite_map::CompositeTraitMap
    TraitsStorage() = new(TraitsMap(), InterfaceMap(), CompositeTraitMap())
end

