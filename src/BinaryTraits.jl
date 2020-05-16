module BinaryTraits

using MacroTools

export BinaryTrait
export @trait, @assign, @implement, @check
export check, istrait, traits, required_contracts
export inittraits

include("types.jl")
include("misc.jl")
include("utils.jl")
include("trait.jl")
include("assignment.jl")
include("interface.jl")

end # module
