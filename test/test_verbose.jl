module Verbose

using BinaryTraits, Test, Logging

# Capture output and make sure that `expected` appears in the log
# when expression `ex` is evaluated
macro testme(expected, ex)
    esc(quote
        buf = IOBuffer()
        with_logger(ConsoleLogger(buf)) do
            @macroexpand($ex)
        end
        s = String(take!(buf))
        @test occursin(Regex($expected), s)
    end)
end

@trait Scratch
struct Cat end

# Testing verbose mode
function test()
    BinaryTraits.set_verbose!(true)
    @testme "Cannot{Scratch}()" @trait Scratch prefix Can,Cannot
    @testme "assign(.*, Cat, Can{Scratch})" @assign Cat with Can{Scratch}
    @testme "function scratch end" @implement Can{Scratch} by scratch(_)
    BinaryTraits.set_verbose!(false)
end

end # module

using Test
@testset "Verbose" begin
    import .Verbose
    Verbose.test()
end
