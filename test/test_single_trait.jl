module SingleTrait

using BinaryTraits, Test

struct Bird end

@test check(SingleTrait, Bird).result == true # everything ok without traits defined

@trait Fly
@assign Bird with Positive{Fly}

function test()
    @test supertype(Fly) === Any
    @test is_trait(Int) == false
    @test is_trait(Fly) == true
    @test is_trait(Positive{Fly}) == true
    @test is_trait(Negative{Fly}) == true
    @test trait(Fly, Bird) == Positive{Fly}()
end

end # module

using Test
@testset "Single Trait" begin
    import .SingleTrait
    SingleTrait.test()
end
