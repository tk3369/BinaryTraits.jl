# Let's play with regular julia types

# First, define traits.
import Base: iterate
@trait Iterable prefix Is,Not
@implement IsIterable by iterate()::Any
@implement IsIterable by iterate(state::Any)::Any

import Base: length
@trait Length prefix Has,No
@implement HasLength by length()::Int

const Int1D = Array{Int,1}
@assign Int1D with Iterable, Length

traits(Int1D)
#=
julia> traits(Int1D)
Set{DataType} with 2 elements:
  HasLength
  IsIterable
=#

# Do we have a good implementation?
@check Int1D
#=
julia> @check Int1D
BinaryTraits.InterfaceReview(Array{Int64,1}) has fully implemented all interface contracts
=#

