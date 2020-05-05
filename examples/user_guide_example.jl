# Quick example

using Revise, BinaryTraits

# Let's define two ability traits
abstract type Ability end
@trait Fly as Ability
@trait Swim as Ability

# Define interface contracts for the type.
@implement CanFly by liftoff(_)
@implement CanFly by fly(_, direction::Float64, altitude::Float64)
@implement CanFly by speed(_)::Float64

# Define a data type and assign it traits.
struct Crane end
@assign Crane with CanFly,CanSwim

# Check compliance.
@check(Crane)
#=
julia> @check(Crane)
┌ Warning: Missing implementation
│   contract = FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = FlyTrait: CanFly ⇢ speed(🔹)::Float64
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = FlyTrait: CanFly ⇢ liftoff(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
❌ Crane is missing these implementations:
1. FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any
2. FlyTrait: CanFly ⇢ speed(🔹)::Float64
3. FlyTrait: CanFly ⇢ liftoff(🔹)::Any
=#

# What about composite traits?
@trait FlySwim with CanFly,CanSwim

# Define a new type and assign with composite trait
struct Swan end
@assign Swan with CanFlySwim

# Check compliance. It should drill down to figure out required interface contracts.
@check(Swan)
#=
julia> @check(Swan)
┌ Warning: Missing implementation
│   contract = FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = FlyTrait: CanFly ⇢ speed(🔹)::Float64
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = FlyTrait: CanFly ⇢ liftoff(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
❌ Swan is missing these implementations:
1. FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any
2. FlyTrait: CanFly ⇢ speed(🔹)::Float64
3. FlyTrait: CanFly ⇢ liftoff(🔹)::Any
=#
