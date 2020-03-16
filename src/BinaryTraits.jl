module BinaryTraits

using MacroTools

export @trait, @assign
export istrait

include("verbose.jl")
include("exception.jl")
include("prefix.jl")
include("utils.jl")
include("macros.jl")

end # module
