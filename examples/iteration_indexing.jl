using Revise, BinaryTraits

# See https://docs.julialang.org/en/v1/manual/interfaces

# -----------------------------------------------------------------------------
# Iteration interface
# -----------------------------------------------------------------------------
import Base: iterate
@trait Iterable prefix Is,Not
@implement IsIterable by iterate(_)::Any
@implement IsIterable by iterate(_, state::Any)::Any

# Example from https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration-1
struct Squares
    count::Int
end

Base.iterate(S::Squares, state=1) = state > S.count ? nothing : (state*state, state+1)

# Let's assign the Squares type to Iterable
@assign Squares with IsIterable
@check(Squares)
#=
julia> @check(Squares)
✅ Squares has implemented:
1. IterableTrait: IsIterable ⇢ iterate(🔹, ::Any)::Any
2. IterableTrait: IsIterable ⇢ iterate(🔹)::Any
=#

# -----------------------------------------------------------------------------
# Indexing interface
# -----------------------------------------------------------------------------
import Base: getindex, setindex!, firstindex, lastindex

@trait Indexable prefix Is,Not
@implement IsIndexable by getindex(_, i::Any)

@trait IndexableFromBeginning prefix Is,Not
@implement IsIndexableFromBeginning by firstindex(_)

@trait IndexableAtTheEnd prefix Is,Not
@implement IsIndexableAtTheEnd by lastindex(_)

# Make sure that `i` is untyped (i.e. `Any`) to adhere to the contract
function Base.getindex(S::Squares, i)
    1 <= i <= S.count || throw(BoundsError(S, i))
    return i*i
end

@assign Squares with IsIndexable
@check(Squares)
#=
julia> @check(Squares)
✅ Squares has implemented:
1. IndexableTrait: IsIndexable ⇢ getindex(🔹, ::Any)::Any
2. IterableTrait: IsIterable ⇢ iterate(🔹, ::Any)::Any
3. IterableTrait: IsIterable ⇢ iterate(🔹)::Any
=#

# We want to have the traits for indexing from beginning and at the end
@assign Squares with IsIndexableFromBeginning, IsIndexableAtTheEnd
@check(Squares)
#=
julia> @check(Squares)
┌ Warning: Missing implementation
│   contract = IndexableAtTheEndTrait: IsIndexableAtTheEnd ⇢ lastindex(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = IndexableFromBeginningTrait: IsIndexableFromBeginning ⇢ firstindex(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
✅ Squares has implemented:
1. IndexableTrait: IsIndexable ⇢ getindex(🔹, ::Any)::Any
2. IterableTrait: IsIterable ⇢ iterate(🔹, ::Any)::Any
3. IterableTrait: IsIterable ⇢ iterate(🔹)::Any
❌ Squares is missing these implementations:
1. IndexableAtTheEndTrait: IsIndexableAtTheEnd ⇢ lastindex(🔹)::Any
2. IndexableFromBeginningTrait: IsIndexableFromBeginning ⇢ firstindex(🔹)::Any
=#

# Let's implement them now.
Base.firstindex(S::Squares) = 1
Base.lastindex(S::Squares) = length(S)
@check(Squares)
#=
julia> @check(Squares)
✅ Squares has implemented:
1. IndexableAtTheEndTrait: IsIndexableAtTheEnd ⇢ lastindex(🔹)::Any
2. IndexableFromBeginningTrait: IsIndexableFromBeginning ⇢ firstindex(🔹)::Any
3. IndexableTrait: IsIndexable ⇢ getindex(🔹, ::Any)::Any
4. IterableTrait: IsIterable ⇢ iterate(🔹, ::Any)::Any
5. IterableTrait: IsIterable ⇢ iterate(🔹)::Any
=#
