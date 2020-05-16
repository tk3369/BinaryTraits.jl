module BinaryTraits

using MacroTools

export BinaryTrait
export @trait, @assign, @implement, @check
export check, is_trait, traits, required_contracts
export init_traits

include("types.jl")
include("misc.jl")
include("utils.jl")
include("trait.jl")
include("assignment.jl")
include("interface.jl")

end # module
