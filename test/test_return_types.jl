module ReturnTypes

using BinaryTraits: has_proper_return_type
using Test
import Base: +

struct MyInt <: Integer
    value::Int
end
+(x::MyInt, y::Integer) = x.value + y

function test()
    # concrete return type, zero ambiguity
    f1(x::Int) = x + 1
    @test has_proper_return_type(f1, Tuple{Int}, Int)
    @test has_proper_return_type(f1, Tuple{Int}, Float64) == false

    # abstract type argument, multiple possible return types
    f2(x::Integer) = x + 1
    @test has_proper_return_type(f2, Tuple{Int}, Int)
    @test has_proper_return_type(f2, Tuple{Int8}, Int)     # due to promotion rule
    @test has_proper_return_type(f2, Tuple{UInt8}, Int)    # due to promotion rule
    @test has_proper_return_type(f2, Tuple{UInt64}, UInt64)
    @test has_proper_return_type(f2, Tuple{Integer}, Int) == false

    # One more level up, int's promoting to Float64.  Complex remains complex.
    f3(x::Number) = x + 1.0
    @test has_proper_return_type(f3, Tuple{Int}, Float64)       # promoted to Float64
    @test has_proper_return_type(f3, Tuple{Complex}, Complex)   # remains complex as input
    @test has_proper_return_type(f3, Tuple{Int}, Int) == false  # negative: no longer int

    # Using custom type

    # We know this has to be an Int
    @test has_proper_return_type(+, Tuple{MyInt,Int}, Int)

    # In this case, the returned type may not be Int because we don't have the concrete
    # type for the 2nd argument.  The result could be anything.
    @test has_proper_return_type(+, Tuple{MyInt,Integer}, Int) == false

    # Same as before, we cannot say the result would be an Integer either.
    @test has_proper_return_type(+, Tuple{MyInt,Integer}, Integer) == false
end

end # module

using Test
@testset "Return Types" begin
    import .ReturnTypes
    ReturnTypes.test()
end
