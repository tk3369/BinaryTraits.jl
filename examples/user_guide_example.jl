# Quick example

using Revise, BinaryTraits

# Let's define two ability traits
abstract type Ability end
@trait Fly as Ability
@trait Swim as Ability

# Define interface contracts for the type.
@implement CanFly by liftoff()
@implement CanFly by fly(direction::Float64, altitude::Float64)
@implement CanFly by speed()::Float64

# Define a data type and assign it traits.
struct Crane end
@assign Crane with CanFly,CanSwim

# Check compliance.
@check(Crane)
#=
julia> @check(Crane)
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ speed(::Crane)::Float64
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:200
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ liftoff(::Crane)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:200
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ fly(::Crane, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:200
❌ Crane is missing these implementations:
1. FlyTrait: CanFly ⇢ speed(::<Type>)::Float64
2. FlyTrait: CanFly ⇢ liftoff(::<Type>)::Any
3. FlyTrait: CanFly ⇢ fly(::<Type>, ::Float64, ::Float64)::Any
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
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ fly(::Swan, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:77
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ speed(::Swan)::Float64
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:77
┌ Warning: Missing implementation: FlyTrait: CanFly ⇢ liftoff(::Swan)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits/src/interface.jl:77
❌ Swan is missing these implementations:
1. FlyTrait: CanFly ⇢ fly(::<Type>, ::Float64, ::Float64)::Any
2. FlyTrait: CanFly ⇢ speed(::<Type>)::Float64
3. FlyTrait: CanFly ⇢ liftoff(::<Type>)::Any
=#
