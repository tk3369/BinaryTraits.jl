module BinaryTraits

using MacroTools

export @trait, @assign
export @implement, @check
export istrait

include("verbose.jl")
include("exception.jl")
include("prefix.jl")
include("utils.jl")
include("macros.jl")
include("interface.jl")

end # module
