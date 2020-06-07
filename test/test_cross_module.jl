module CrossModule

using BinaryTraits
using Test, Logging

module X
    using BinaryTraits
    using BinaryTraits.Prefix: Is
    @trait RowTable
    @implement Is{RowTable} by row(_, ::Integer)
    __init__() = init_traits(@__MODULE__)
end

module Y
    using Test
    using BinaryTraits
    using BinaryTraits.Prefix: Is
    using ..X
    struct AwesomeTable end
    @assign AwesomeTable with Is{X.RowTable}
    r = @check(AwesomeTable)
    @test r.implemented |> length == 0
    X.row(::AwesomeTable, ::Number) = 1
    __init__() = init_traits(@__MODULE__)
end

function test()
        r = @check(Y.AwesomeTable)
        @test r.implemented |> length == 1
end

end # module

using Test
@testset "Cross Module" begin
    import .CrossModule
    CrossModule.test()
end
