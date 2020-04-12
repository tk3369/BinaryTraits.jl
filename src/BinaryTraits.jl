module BinaryTraits

using MacroTools

export @trait, @assign, @implement
export traits, istrait, check, required_contracts

include("misc.jl")
include("utils.jl")
include("trait.jl")
include("interface.jl")

end # module
