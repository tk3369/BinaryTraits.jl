# See https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array-1
using Revise, BinaryTraits

import Base: size, getindex, setindex!

# -----------------------------------------------------------------------------
# AbstractArray interface
# -----------------------------------------------------------------------------

@trait Dimension prefix Has,No
@implement HasDimension by size(_)::Tuple

# Bottom is used due to duck typing of the value `v` below
const Bottom = Base.Bottom

@trait LinearIndexing prefix Has,No
@implement HasLinearIndexing by getindex(_, i::Int)
@implement HasLinearIndexing by setindex!(_, v::Bottom, i::Int)

const IntVarArg = Vararg{Int, N} where N

@trait CartesianIndexing prefix Has,No
@implement HasCartesianIndexing by getindex(_, I::IntVarArg)
@implement HasCartesianIndexing by setindex!(_, v::Bottom, I::IntVarArg)

# -----------------------------------------------------------------------------
# Example: 1-D Int array
# -----------------------------------------------------------------------------
const Array1DInt = Array{Int,1}

@assign Array1DInt with HasDimension
@check(Array1DInt)
#=
julia> @check(Array1DInt)
✅ Array{Int64,1} has implemented:
1. DimensionTrait: HasDimension ⇢ size(🔹)::Tuple
=#

@assign Array1DInt with HasLinearIndexing
@check(Array1DInt)
#=
julia> @check(Array1DInt)
✅ Array{Int64,1} has implemented:
1. DimensionTrait: HasDimension ⇢ size(🔹)::Tuple
2. LinearIndexingTrait: HasLinearIndexing ⇢ getindex(🔹, ::Int64)::Any
3. LinearIndexingTrait: HasLinearIndexing ⇢ setindex!(🔹, ::Union{}, ::Int64)::Any
=#

# 1D array is a specialized version of CartesianIndexing.
# Let's verify.
@assign Array1DInt with HasCartesianIndexing
@check(Array1DInt)
#=
julia> @check(Array1DInt)
✅ Array{Int64,1} has implemented:
1. CartesianIndexingTrait: HasCartesianIndexing ⇢ getindex(🔹, ::Vararg{Int64,N} where N)::Any
2. CartesianIndexingTrait: HasCartesianIndexing ⇢ setindex!(🔹, ::Union{}, ::Vararg{Int64,N} where N)::Any
3. DimensionTrait: HasDimension ⇢ size(🔹)::Tuple
4. LinearIndexingTrait: HasLinearIndexing ⇢ getindex(🔹, ::Int64)::Any
5. LinearIndexingTrait: HasLinearIndexing ⇢ setindex!(🔹, ::Union{}, ::Int64)::Any
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
