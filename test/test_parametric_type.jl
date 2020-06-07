module ParametricTypes

using BinaryTraits
using Test

# define trait with predefined parametric types (short-hand without import)
@trait Iterable prefix Is,Not
@assign AbstractArray with Is{Iterable}

# holy trait dispatch
next(x::T) where T = next(trait(Iterable, T), x)
next(::Is{Iterable}, x) = iterate(x)
next(::Not{Iterable}, x) = :toobad

function test()
    @test next([1,2,3]) !== nothing
    @test next(:hello) === :toobad
end

end # module

using Test
@testset "Parametric Types" begin
    import .ParametricTypes
    ParametricTypes.test()
end
