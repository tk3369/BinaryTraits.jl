using Revise, BinaryTraits

# Simulate the case that Base defines the Iterable interface and its contracts
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration-1
import Base: iterate
@trait Iterable prefix Is,Not
@implement Iterable by iterate()::Any
@implement Iterable by iterate(state::Any)::Any

# In my module, I have a struct that I wish to implement Iterable interface
struct Counter
    n::Int
end

# And, I affirm that my implementation satisfies the Iterable interface
@assign Counter with Iterable

# In my module initialization function, I can validate my implementation.
@check Counter

# now define iterate function
Base.iterate(c::Counter, state = 0) = c.n > state ? (state+1,state+1) : nothing

# now fully implemented
@check Counter

# ok to use
sum(x for x in Counter(3))

# But array comprehension is broken without a length
[x for x in Counter(3)]

# Create new Length trait
import Base: length
@trait Length prefix Has,No
@implement Length by length()::Int

# Associate my type to the Length trait
@assign Counter with Length
@check Counter  # not fully implemented yet

Base.length(c::Counter) = c.n
@check Counter  # all good

[x for x in Counter(3)]


