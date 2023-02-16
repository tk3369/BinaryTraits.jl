module HierarchicalInterfaces

using BinaryTraits
using Test

abstract type Bird end
struct Penguin <: Bird end
struct Ostrich <: Bird end

@trait Fly
@implement Negative{Fly} by fly(_)
@assign Bird with Positive{Fly}
@assign Penguin with Negative{Fly}
@assign Ostrich with Negative{Fly}

@traitfn fly(::Positive{Fly}) = "Flap!"

fly(::Ostrich) = "I'm a flightless bird!"

# Penguin should not satisfy the interface
function test_negative()
    check_result = @check(Penguin)
    @test check_result.result == false
end

# Ostrich does satisfy the interface
function test_positive()
    check_result = @check(Ostrich)
    @test check_result.result == true
end

end

using .HierarchicalInterfaces
HI = HierarchicalInterfaces

HI.test_negative()
HI.test_positive()