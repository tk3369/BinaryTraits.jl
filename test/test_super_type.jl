module SuperType

using BinaryTraits, Test

struct Duck end
abstract type Mobility end

@trait Fly as Mobility

function test()
    @test supertype(Fly) === Mobility
end

end # module

using Test
@testset "Super Type" begin
    import .SuperType
    SuperType.test()
end
