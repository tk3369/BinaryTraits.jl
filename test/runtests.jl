using Test

@testset "BinaryTraits Tests" begin
    include("test_super_type.jl")
    include("test_syntax.jl")
    include("test_single_trait.jl")
    include("test_multiple_traits.jl")
    include("test_composite_traits.jl")
    include("test_verbose.jl")
    include("test_parametric_type.jl")
    include("test_cross_module.jl")
    include("test_interfaces.jl")
    include("test_traitfn.jl")
    VERSION >= v"1.1" && include("test_return_types.jl")
end
