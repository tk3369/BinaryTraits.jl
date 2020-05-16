# See https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array-1
using BinaryTraits: @trait, @implement, @check
using Prefix: Has, No

import Base: size, getindex, setindex!

# -----------------------------------------------------------------------------
# AbstractArray interface
# -----------------------------------------------------------------------------

@trait Dimension
@implement Has{Dimension} by size(_)::Tuple

# Bottom is used due to duck typing of the value `v` below
const Bottom = Base.Bottom

@trait LinearIndexing
@implement Has{LinearIndexing} by getindex(_, i::Int)
@implement Has{LinearIndexing} by setindex!(_, v::Bottom, i::Int)

const IntVarArg = Vararg{Int, N} where N

@trait CartesianIndexing
@implement Has{CartesianIndexing} by getindex(_, I::IntVarArg)
@implement Has{CartesianIndexing} by setindex!(_, v::Bottom, I::IntVarArg)

# -----------------------------------------------------------------------------
# Example: 1-D Int array
# -----------------------------------------------------------------------------
const Array1DInt = Array{Int,1}

@assign Array1DInt with Has{Dimension}
@check(Array1DInt)
#=
julia> @check(Array1DInt)
✅ Array{Int64,1} has implemented:
1. BinaryTrait{Dimension}: Positive{Dimension} ⇢ size(🔹)::Tuple
=#

@assign Array1DInt with Has{LinearIndexing}
@check(Array1DInt)
#=
julia> @check(Array1DInt)
✅ Array{Int64,1} has implemented:
1. BinaryTrait{Dimension}: Positive{Dimension} ⇢ size(🔹)::Tuple
2. BinaryTrait{LinearIndexing}: Positive{LinearIndexing} ⇢ getindex(🔹, ::Int64)::Any
3. BinaryTrait{LinearIndexing}: Positive{LinearIndexing} ⇢ setindex!(🔹, ::Union{}, ::Int64)::Any
=#

# 1D array is a specialized version of CartesianIndexing.
# Let's verify.
@assign Array1DInt with Has{CartesianIndexing}
@check(Array1DInt)
#=
julia> @check(Array1DInt)
✅ Array{Int64,1} has implemented:
1. BinaryTrait{Dimension}: Positive{Dimension} ⇢ size(🔹)::Tuple
2. BinaryTrait{LinearIndexing}: Positive{LinearIndexing} ⇢ getindex(🔹, ::Int64)::Any
3. BinaryTrait{CartesianIndexing}: Positive{CartesianIndexing} ⇢ getindex(🔹, ::Vararg{Int64,N} where N)::Any
4. BinaryTrait{CartesianIndexing}: Positive{CartesianIndexing} ⇢ setindex!(🔹, ::Union{}, ::Vararg{Int64,N} where N)::Any
5. BinaryTrait{LinearIndexing}: Positive{LinearIndexing} ⇢ setindex!(🔹, ::Union{}, ::Int64)::Any
=#

# -----------------------------------------------------------------------------
# Example: SquaresVector
# -----------------------------------------------------------------------------

struct SquaresVector <: AbstractArray{Int, 1}
    count::Int
end

Base.size(S::SquaresVector) = (S.count,)
Base.getindex(S::SquaresVector, i::Int) = i*i

@assign SquaresVector with HasDimension,HasLinearIndexing
@check(SquaresVector)
#=
julia> @check(SquaresVector)
✅ SquaresVector has implemented:
1. DimensionTrait: HasDimension ⇢ size(🔹)::Tuple
2. LinearIndexingTrait: HasLinearIndexing ⇢ getindex(🔹, ::Int64)::Any
3. LinearIndexingTrait: HasLinearIndexing ⇢ setindex!(🔹, ::Union{}, ::Int64)::Any
=#
