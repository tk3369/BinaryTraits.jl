module MultipleTraits

using BinaryTraits
using BinaryTraits.Prefix: Can, Cannot
using Test

struct Duck end
struct Dog end

@trait Fly
@trait Swim

@assign Duck with Can{Fly}, Can{Swim}
@assign Dog with Can{Swim}

function test()
    @test trait(Fly, Dog)   isa Cannot{Fly}
    @test trait(Swim, Dog)  isa Can{Swim}
    @test trait(Fly, Duck)  isa Can{Fly}
    @test trait(Swim, Duck) isa Can{Swim}
end

end # module

using Test
@testset "Multiple Traits" begin
    import .MultipleTraits
    MultipleTraits.test()
end
