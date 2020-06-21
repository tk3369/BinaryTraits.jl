module BinaryTraits

using MacroTools: rmlines, postwalk
using ExprTools: splitdef, combinedef

export BinaryTrait
export @trait, @assign, @implement, @check, @holy
export check, is_trait, traits, required_contracts
export init_traits

include("types.jl")
include("misc.jl")
include("utils.jl")
include("trait.jl")
include("assignment.jl")
include("interface.jl")
include("holy.jl")

end # module
