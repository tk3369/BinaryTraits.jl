# Quick example

using Revise, BinaryTraits

abstract type Ability end
@trait Fly as Ability
@trait Swim as Ability
@trait FlySwim with Fly,Swim

struct Crane end
@assign Crane with Fly,Swim

@implement CanFly by liftoff()
@implement CanFly by fly(direction::Float64, altitude::Float64)
@implement CanFly by speed()::Float64

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
