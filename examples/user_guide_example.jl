# Quick example

using BinaryTraits
using BinaryTraits.Prefix: Can

# Let's define two ability traits
abstract type Ability end
@trait Fly as Ability
@trait Swim as Ability

# Define interface contracts for the type.
@implement Can{Fly} by liftoff(_)
@implement Can{Fly} by fly(_, direction::Float64, altitude::Float64)
@implement Can{Fly} by speed(_)::Float64

# Define a data type and assign it traits.
struct Crane end
@assign Crane with Can{Fly},Can{Swim}

# Check compliance.
@check(Crane)
#=
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ liftoff(🔹)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ speed(🔹)::Float64
└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59
❌ Crane is missing these implementations:
1. BinaryTrait{Fly}: Positive{Fly} ⇢ liftoff(🔹)::Any
2. BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
3. BinaryTrait{Fly}: Positive{Fly} ⇢ speed(🔹)::Float64
=#

# What about composite traits?
@trait FlySwim with Can{Fly},Can{Swim}

# Define a new type and assign with composite trait
struct Swan end
@assign Swan with Can{Fly}, Can{Swim}

# Check compliance. It should automatically drill down to figure out
# the required interface contracts.
@check(Swan)
#=
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ liftoff(🔹)::Any
└ @ BinaryTraits ~/Library/Mobile Documents/com~apple~CloudDocs/Programming/Julia/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
└ @ BinaryTraits ~/Library/Mobile Documents/com~apple~CloudDocs/Programming/Julia/BinaryTraits.jl/src/interface.jl:59
┌ Warning: Missing implementation
│   contract = BinaryTrait{Fly}: Positive{Fly} ⇢ speed(🔹)::Float64
└ @ BinaryTraits ~/Library/Mobile Documents/com~apple~CloudDocs/Programming/Julia/BinaryTraits.jl/src/interface.jl:59
❌ Swan is missing these implementations:
1. BinaryTrait{Fly}: Positive{Fly} ⇢ liftoff(🔹)::Any
2. BinaryTrait{Fly}: Positive{Fly} ⇢ fly(🔹, ::Float64, ::Float64)::Any
3. BinaryTrait{Fly}: Positive{Fly} ⇢ speed(🔹)::Float64
=#
