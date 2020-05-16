using BinaryTraits
using BinaryTraits.Prefix: Is, Not

# See https://docs.julialang.org/en/v1/manual/interfaces

# -----------------------------------------------------------------------------
# Iteration interface
# -----------------------------------------------------------------------------
import Base: iterate
@trait Iterable
@implement Is{Iterable} by iterate(_)::Any
@implement Is{Iterable} by iterate(_, state::Any)::Any

# Example from https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration-1
struct Squares
    count::Int
end

Base.iterate(S::Squares, state=1) = state > S.count ? nothing : (state*state, state+1)

# Let's assign the Squares type to Iterable
@assign Squares with Is{Iterable}
@check(Squares)
#=
julia> @check(Squares)
✅ Squares has implemented:
1. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹)::Any
2. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹, ::Any)::Any
=#

# -----------------------------------------------------------------------------
# Indexing interface
# -----------------------------------------------------------------------------
import Base: getindex, setindex!, firstindex, lastindex

@trait Indexable
@implement Is{Indexable} by getindex(_, i::Any)

@trait IndexableFromBeginning
@implement Is{IndexableFromBeginning} by firstindex(_)

@trait IndexableAtTheEnd
@implement Is{IndexableAtTheEnd} by lastindex(_)

# Make sure that `i` is untyped (i.e. `Any`) to adhere to the contract
function Base.getindex(S::Squares, i)
    1 <= i <= S.count || throw(BoundsError(S, i))
    return i*i
end

@assign Squares with Is{Indexable}
@check(Squares)
#=
julia> @check(Squares)
✅ Squares has implemented:
1. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹)::Any
2. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹, ::Any)::Any
3. BinaryTrait{Indexable}: Positive{Indexable} ⇢ getindex(🔹, ::Any)::Any
=#

# We want to have the traits for indexing from beginning and at the end
@assign Squares with Is{IndexableFromBeginning}, Is{IndexableAtTheEnd}
@check(Squares)
#=
julia> @check(Squares)
┌ Warning: Missing implementation
│   contract = BinaryTrait{IndexableFromBeginning}: Positive{IndexableFromBeginning} ⇢ firstindex(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = BinaryTrait{IndexableAtTheEnd}: Positive{IndexableAtTheEnd} ⇢ lastindex(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
✅ Squares has implemented:
1. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹)::Any
2. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹, ::Any)::Any
3. BinaryTrait{Indexable}: Positive{Indexable} ⇢ getindex(🔹, ::Any)::Any
❌ Squares is missing these implementations:
1. BinaryTrait{IndexableFromBeginning}: Positive{IndexableFromBeginning} ⇢ firstindex(🔹)::Any
2. BinaryTrait{IndexableAtTheEnd}: Positive{IndexableAtTheEnd} ⇢ lastindex(🔹)::Any
=#

# Let's implement them now.
Base.firstindex(S::Squares) = 1
Base.lastindex(S::Squares) = length(S)
@check(Squares)
#=
julia> @check(Squares)
✅ Squares has implemented:
1. BinaryTrait{IndexableFromBeginning}: Positive{IndexableFromBeginning} ⇢ firstindex(🔹)::Any
2. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹)::Any
3. BinaryTrait{Iterable}: Positive{Iterable} ⇢ iterate(🔹, ::Any)::Any
4. BinaryTrait{Indexable}: Positive{Indexable} ⇢ getindex(🔹, ::Any)::Any
5. BinaryTrait{IndexableAtTheEnd}: Positive{IndexableAtTheEnd} ⇢ lastindex(🔹)::Any
=#
