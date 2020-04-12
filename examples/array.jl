# Let's play with regular julia types
using Revise, BinaryTraits

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
check(Int1D)
#=
julia> check(Int1D)
✅ Array{Int64,1} has implemented:
1. LengthTrait: HasLength ⇢ length(::<Type>)::Int64
2. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
3. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
=#

# Which contracts are required?
required_contracts(Int1D)
#=
julia> required_contracts(Int1D)
2-element Array{Pair{DataType,Set{BinaryTraits.Contract}},1}:
   LengthTrait => Set([LengthTrait: HasLength ⇢ length(::<Type>)::Int64])
 IterableTrait => Set([IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any, IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any])
=#
