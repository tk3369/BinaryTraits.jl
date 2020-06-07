module CompositeTraits

using BinaryTraits
using BinaryTraits.Prefix: Has, Is, Not, Can
using Test

# possible traits
@trait Move
@trait CarryPassenger
@trait FourWheels
@trait Engine

# assignments
struct Acura end
@assign Acura with Can{Move}, Can{CarryPassenger}, Has{FourWheels}, Has{Engine}

struct Tricycle end
@assign Tricycle with Can{Move}, Can{CarryPassenger}

# composite
@trait Car with Can{Move}, Can{CarryPassenger}, Has{FourWheels}, Has{Engine}

function test()
    @test trait(Car, Acura) == Is{Car}()
    @test trait(Car, Tricycle) == Not{Car}()
end

end # module

using Test
@testset "Composite Traits" begin
    import .CompositeTraits
    CompositeTraits.test()
end
