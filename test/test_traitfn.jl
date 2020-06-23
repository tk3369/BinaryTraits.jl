module HolyTraitsDispatch

using BinaryTraits
using BinaryTraits.Prefix: Is, Not
using Test

# Traits used in this test
import Base: getindex
@trait Indexable
@implement Is{Indexable} by getindex(_, v::Integer)
@assign AbstractArray with Is{Indexable}
@assign AbstractString with Is{Indexable}

import Base: collect
@trait Collectable
@implement Is{Collectable} by collect(_)
@assign Base.Generator with Is{Collectable}

function test()

    @testset "General dispatch" begin
        @traitfn head(v::Is{Indexable}) = :index     # v[1]
        @traitfn head(v::Not{Indexable}) = :notindex # first(v[1])
        @test head([1,2,3]) == :index
        @test head("abcde") == :index
        @test head(i for i in 4:6) == :notindex
    end

    @testset "Keyword args handling" begin
        @traitfn function increment(x::Is{Indexable}, i::Int; by = 1)
            x[i] += by
        end
        @test increment([1,2,3], 2; by = 2) == 4
    end

    @testset "Where-clause handling" begin
        @traitfn function addfirst(y::Vector{T}, x::Is{Indexable}) where {T <: AbstractFloat}
            return y .+ x[1]
        end
        @test addfirst([1.0, 2.0, 3.0], [1, 2, 3]) == [2.0, 3.0, 4.0]
    end

    @testset "Unnamed args" begin
        @traitfn unamed(v::Is{Indexable}, ::Int) = :int       # unamed regular position arg
        @traitfn unamed(::Is{Indexable}, v::String) = :string # unamed trait arg
        @traitfn unamed(::Is{Indexable}, ::Bool) = :bool      # unamed all!
        @test unamed([1,2,3], 1) == :int
        @test unamed([1,2,3], "abc") == :string
        @test unamed([1,2,3], true) == :bool
    end

    @testset "Duck typed arg" begin
        @traitfn duckarg(::Is{Indexable}, v) = :quack
        @test duckarg([1,2,3], true) == :quack
    end

    @testset "Multi-trait dispatch" begin
        # How do we use more than one trait for the same argument?
        # There are 2^n cases (n = number of traits).
        # However, it can be simplified using `BinaryTrait{T}` when cases overlap.
        @traitfn seek(v::Is{Indexable},  w::BinaryTrait{Collectable}, i::Integer)  = :index
        @traitfn seek(v::Not{Indexable}, w::Is{Collectable}, i::Integer) = :collect
        @traitfn seek(v::Not{Indexable}, w::Not{Collectable}, i::Integer) = :error
        seek(v, i::Integer) = seek(v, v, i)   # write a custom dispatcher that duplicates the arg

        @test seek([1,2,3], 2) == :index
        @test seek((i for i in 4:6), 2) == :collect
        @test seek(123, 1) == :error
    end
end

end # module

using Test
@testset "Holy Traits dispatch" begin
    import .HolyTraitsDispatch
    HolyTraitsDispatch.test()
end
