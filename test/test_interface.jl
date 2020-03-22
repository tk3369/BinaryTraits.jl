using Revise
using BinaryTraits
using Test

@trait Fly

@implement Fly by liftoff()
# expands to...
# function liftoff end
# BinaryTraits.register(Main, FlyTrait, liftoff, ())

@implement Fly by speed(altitude::Float64, resistence::Float64)::Float64
# expands to...
# function speed end
# BinaryTraits.register(Main, FlyTrait, speed, (Float64,Float64), Float64)

# example usage
struct Duck
    name::String
    speed::Float64
end
@assign Duck with Fly

# expect two warnings
result = @check Duck
@test result.fully_implemented == false
@test length(result.missing_contracts) == 2

liftoff(d::Duck) = "Hi ho!"

# expect one warning
result = @check Duck
@test result.fully_implemented == false
@test length(result.missing_contracts) == 1

function speed(d::Duck, altitude::Float64, resistence::Float64)
    d.speed - altitude/10 - resistence
end

result = @check Duck
@test result.fully_implemented == true
@test length(result.missing_contracts) == 0
