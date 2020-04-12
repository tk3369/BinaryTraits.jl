using Revise, BinaryTraits

# See https://docs.julialang.org/en/v1/manual/interfaces

# -----------------------------------------------------------------------------
# Iteration interface
# -----------------------------------------------------------------------------
import Base: iterate
@trait Iterable prefix Is,Not
@implement IsIterable by iterate()::Any
@implement IsIterable by iterate(state::Any)::Any

# Example from https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration-1
struct Squares
    count::Int
end

Base.iterate(S::Squares, state=1) = state > S.count ? nothing : (state*state, state+1)

# Let's assign the Squares type to Iterable
@assign Squares with Iterable
check(Squares)
#=
julia> check(Squares)
✅ Squares has implemented:
1. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
2. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
=#

# -----------------------------------------------------------------------------
# Indexing interface
# -----------------------------------------------------------------------------
import Base: getindex, setindex!, firstindex, lastindex

@trait Indexable prefix Is,Not
@implement IsIndexable by getindex(i::Any)

@trait IndexableFromBeginning prefix Is,Not
@implement IsIndexableFromBeginning by firstindex()

@trait IndexableAtTheEnd prefix Is,Not
@implement IsIndexableAtTheEnd by lastindex()

# Make sure that `i` is untyped (i.e. `Any`) to adhere to the contract
function Base.getindex(S::Squares, i)
    1 <= i <= S.count || throw(BoundsError(S, i))
    return i*i
end

@assign Squares with Indexable
check(Squares)
#=
julia> check(Squares)
✅ Squares has implemented:
1. IndexableTrait: IsIndexable ⇢ getindex(::<Type>, ::Any)::Any
2. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
3. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
=#

# We want to have the traits for indexing from beginning and at the end
@assign Squares with IndexableFromBeginning, IndexableAtTheEnd
check(Squares)
#=
✅ Squares has implemented:
1. IndexableTrait: IsIndexable ⇢ getindex(::<Type>, ::Any)::Any
2. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
3. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
❌ Squares is missing these implementations:
1. IndexableFromBeginningTrait: IsIndexableFromBeginning ⇢ firstindex(::<Type>)::Any
2. IndexableAtTheEndTrait: IsIndexableAtTheEnd ⇢ lastindex(::<Type>)::Any
=#

# Let's implement them now.
Base.firstindex(S::Squares) = 1
Base.lastindex(S::Squares) = length(S)
check(Squares)
#=
julia> check(Squares)
✅ Squares has implemented:
1. IndexableTrait: IsIndexable ⇢ getindex(::<Type>, ::Any)::Any
2. IndexableFromBeginningTrait: IsIndexableFromBeginning ⇢ firstindex(::<Type>)::Any
3. IndexableAtTheEndTrait: IsIndexableAtTheEnd ⇢ lastindex(::<Type>)::Any
4. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
5. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
=#
