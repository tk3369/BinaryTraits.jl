using BinaryTraits
using BinaryTraits.Prefix: Is, Not
using Test

# Indexable trait means you can get an element by an integer value
import Base: getindex
@trait Indexable
@implement Is{Indexable} by getindex(_, v::Integer)

# Any array should be indexable!
@assign AbstractArray with Is{Indexable}
@check AbstractArray

# These functions should dispatch properly for all Indexable objects
@traitfn head(v::Is{Indexable}) = "using getindex" # v[1]
@traitfn head(v::Not{Indexable}) = "using first"   # first(v[1])

# Let's test!
@test head([1,2,3]) == "using getindex"
@test head(i for i in 4:6) == "using first"

# Isn't String also indexable?  No problem.
@assign AbstractString with Is{Indexable}
@test head("abcde") == "using getindex"

# This wouldn't work :-(
#=
julia> [1,2,3] + (i for i in 4:6)
ERROR: MethodError: no method matching +(::Array{Int64,1}, ::Base.Generator{UnitRange{Int64},typeof(identity)})
=#

# But, we can turn anything collectable into indexable by collecting it first :-)
import Base: collect
@trait Collectable
@implement Is{Collectable} by collect(_)

@assign Base.Generator with Is{Collectable}
@check Base.Generator

@traitfn Base.:+(v::Is{Indexable}, w::Is{Collectable}) = v + collect(w)

# Nice!
#=
julia> [1,2,3] + (i for i in 4:6)
3-element Array{Int64,1}:
 5
 7
 9
=#

# Let's make sure kwargs works properly
@traitfn function increment(x::Is{Indexable}, i::Int; by = 1)
    x[i] += by
end
@test increment([1,2,3], 2; by = 2) == 4

# What about any existing where-parameters?
@traitfn function add_first(y::Vector{T}, x::Is{Indexable}) where {T <: AbstractFloat}
    return y .+ x[1]
end
@test add_first([1.0, 2.0, 3.0], [1, 2, 3]) == [2.0, 3.0, 4.0]

# How to access the concrete type of a trait arg?
@traitfn function my_type(x::Is{Indexable})
    return typeof(x)
end
@test my_type([1,2,3]) == Vector{Int}

# How do we use more than one trait for the same argument?
# There are 2^n cases (n = number of traits).
# However, it can be simplified using `BinaryTrait{T}` when cases overlap.
@traitfn seek(v::Is{Indexable},  w::BinaryTrait{Collectable}, i::Integer)  = "using index"
@traitfn seek(v::Not{Indexable}, w::Is{Collectable}, i::Integer) = "using collect"
@traitfn seek(v::Not{Indexable}, w::Not{Collectable}, i::Integer) = error("sorry")
seek(v, i::Integer) = seek(v, v, i)   # write a custom dispatcher that duplicates the arg

@test seek([1,2,3], 2) == "using index"
@test seek((i for i in 4:6), 2) == "using collect"
@test_throws ErrorException seek(123, 1)

# Another option is to not use the @traitfn macro and roll your own dispatch
function locate(v::T, i::Integer) where T
    if trait(Indexable, T) isa Positive
        "using index"
    elseif trait(Collectable, T) isa Positive
        "using collect"
    else
        error("sorry")
    end
end
@test locate([1,2,3], 2) == "using index"
@test locate((i for i in 4:6), 2) == "using collect"

