using Revise, BinaryTraits

# Simulate the case that Base defines the Iterable interface and its contracts
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration-1
import Base: iterate
@trait Iterable prefix Is,Not
@implement IsIterable by iterate()::Any
@implement IsIterable by iterate(state::Any)::Any

# In my module, I have a struct that I wish to implement Iterable interface
struct Counter
    n::Int
end

# And, I affirm that my implementation satisfies the Iterable interface
@assign Counter with Iterable

# In my module initialization function, I can validate my implementation.
check(Counter)
#=
julia> check(Counter)
┌ Warning: Missing implementation: IterableTrait: IsIterable ⇢ iterate(::Counter)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:169
┌ Warning: Missing implementation: IterableTrait: IsIterable ⇢ iterate(::Counter, ::Any)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:169
❌ Counter is missing these implementations:
1. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
2. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
=#

# now define iterate function
Base.iterate(c::Counter, state = 0) = c.n > state ? (state+1,state+1) : nothing

# now fully implemented
check(Counter)
#=
julia> check(Counter)
✅ Counter has implemented:
1. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
2. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
=#

# ok to use
sum(x for x in Counter(3))
#=
julia> sum(x for x in Counter(3))
6
=#

# But array comprehension is broken without a length
[x for x in Counter(3)]
#=
julia> [x for x in Counter(3)]
ERROR: MethodError: no method matching length(::Counter)
=#

# Create new Length trait
import Base: length
@trait Length prefix Has,No
@implement HasLength by length()::Int

# Associate my type to the Length trait
@assign Counter with Length
check(Counter)  # not fully implemented yet
#=
julia> check(Counter)  # not fully implemented yet
┌ Warning: Missing implementation: LengthTrait: HasLength ⇢ length(::Counter)::Int64
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:169
✅ Counter has implemented:
1. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
2. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
❌ Counter is missing these implementations:
1. LengthTrait: HasLength ⇢ length(::<Type>)::Int64
=#

Base.length(c::Counter) = c.n
check(Counter)
#=
julia> check(Counter)
✅ Counter has implemented:
1. LengthTrait: HasLength ⇢ length(::<Type>)::Int64
2. IterableTrait: IsIterable ⇢ iterate(::<Type>)::Any
3. IterableTrait: IsIterable ⇢ iterate(::<Type>, ::Any)::Any
=#

[x for x in Counter(3)]  # Hooray!
#=
julia> [x for x in Counter(3)]  # Hooray!
3-element Array{Int64,1}:
 1
 2
 3
=#

# What have we done so far?
traits(Counter)
#=
julia> traits(Counter)
Set{DataType} with 2 elements:
  HasLength
  IsIterable
=#

@trait Comprehensible prefix Is,Not with Iterable,Length
@assign Counter with Comprehensible

# Is a Counter comprehensible?  It better be!
comprehensibletrait(Counter(2))
#=
julia> comprehensibletrait(Counter(2))
IsComprehensible()
=#

