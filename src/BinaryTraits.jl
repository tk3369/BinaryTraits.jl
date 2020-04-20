module BinaryTraits

using MacroTools

export @trait, @assign, @implement, @check
export istrait, traits, required_contracts

include("types.jl")
include("misc.jl")
include("utils.jl")
include("trait.jl")
include("assignment.jl")
include("interface.jl")

end # module
